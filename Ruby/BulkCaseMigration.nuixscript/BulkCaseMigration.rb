script_directory = File.dirname(__FILE__)
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.dialogs.ProcessingStatusDialog"
java_import "com.nuix.nx.digest.DigestHelper"
java_import "com.nuix.nx.controls.models.Choice"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

# Load up SuperUtilities for helper methods
require File.join(script_directory,"SuperUtilities.jar")
java_import com.nuix.superutilities.SuperUtilities
$su = SuperUtilities.init($utilities,NUIX_VERSION)

require 'csv'

# ======================
# Define settings dialog
# ======================
dialog = TabbedCustomDialog.new("Bulk Case Migrater")

main_tab = dialog.addTab("main_tab","Main")
main_tab.appendSaveFileChooser("report_csv","Report CSV","Comma Separated Values","csv")
main_tab.appendHeader("Case Directories")
main_tab.appendCheckBox("search_subdirectories","Search Sub-Directories",true)
main_tab.appendPathList("case_directories")
main_tab.getControl("case_directories").setFilesButtonVisible(false)

backups_tab = dialog.addTab("backups_tab","Backups")
backups_tab.appendCheckBox("create_backups","Create Backups",false)
backups_tab.appendDirectoryChooser("backup_directory","Backups Directory")
backups_tab.appendSpinner("compression_level","Compression (0-9)",5,0,9)
backups_tab.enabledOnlyWhenChecked("backup_directory","create_backups")
backups_tab.enabledOnlyWhenChecked("compression_level","create_backups")

# ============================
# Validate user settings a bit
# ============================
dialog.validateBeforeClosing do |values|
	# Make sure user provided CSV report file path
	if values["report_csv"].nil? || values["report_csv"].strip.empty?
		CommonDialogs.showWarning("Please provide a file path for report CSV.")
		next false
	end

	# Make sure user provided at least 1 case directory or directory to search for cases
	if values["case_directories"].size < 1
		CommonDialogs.showWarning("Please provide at least one case directory.")
		next false
	else
		# Make sure all provided directories actually exist
		all_directories_exist = true
		values["case_directories"].each_with_index do |case_directory,case_directory_index|
			if !java.io.File.new(case_directory).exists
				CommonDialogs.showError("Case directory #{case_directory_index+1} does not exist:\n\n#{case_directory}")
				all_directories_exist = false
				break
			end
		end
		if !all_directories_exist
			next false
		end
	end

	# Validate settings regarding backups
	if values["create_backups"]
		if values["backup_directory"].strip.empty?
			CommonDialogs.showError("Please provide a value for 'Backups Directory'")
			next false
		end
	end

	next true
end

# Display dialog
dialog.display

# If everything looks good, get to work
if dialog.getDialogResult == true

	values = dialog.toMap
	search_subdirectories = values["search_subdirectories"]
	case_directories = values["case_directories"]
	report_csv = values["report_csv"]

	create_backups = values["create_backups"]
	backup_directory = values["backup_directory"]
	compression_level = values["compression_level"]

	current_case_index = 0
	name_strip = /[<>:\\"\|\?\*\[\]]/i

	case_processor = $su.createBulkCaseProcessor
	case_processor.setAllowCaseMigration(true)

	ProgressDialog.forBlock do |pd|
		super_case_utility = $su.getCaseUtility

		if search_subdirectories
			case_directories = case_directories.map do |case_directory|
				pd.logMessage("Searching sub-directories for cases: #{case_directory}")
				paths = super_case_utility.findCaseDirectoryPaths(case_directory)
				paths.each{|path|pd.logMessage("Found: #{path}")}
				next paths
			end
			case_directories = case_directories.flatten
		end

		result_data = {}

		# Define action to be performed before opening each case
		case_processor.beforeOpeningCase do |case_info|
			current_case_index += 1
			result_data[case_info.getGuid] = {
				:case_name => case_info.getName,
				:case_directory => case_info.getCaseDirectoryPath,
				:migration_status => "",
				:backup_file => "",
			}

			if create_backups
				pd.setMainStatus("Backing up case: #{case_info.getCaseDirectoryPath}")
				if case_info.isLocked
					pd.logMessage("Case seems to be locked, backup skipped...")
				else
					timestamp = org.joda.time.DateTime.now.toString("YYYYMMDD-HHmmSS")
					archive_file_name = "#{case_info.getName}_#{timestamp}.zip"
					archive_file_name = archive_file_name.gsub(name_strip,"_")
					archive_file = File.join(backup_directory,archive_file_name)
					begin
						pd.logMessage("Backing up case:")
						pd.logMessage("  Case Directory: #{case_info.getCaseDirectoryPath}")
						pd.logMessage("    Archive File: #{archive_file}")
						super_case_utility.archiveCase(case_info.getCaseDirectoryPath,archive_file,false,compression_level)
						result_data[case_info.getGuid][:backup_file] = archive_file
						pd.logMessage("Backup Completed")
					rescue Exception => exc
						pd.logMessage("Error While Backing Up Case: #{exc.message}\n#{exc.backtrace.join("\n")}")
					end
				end
			else
				result_data[case_info.getGuid][:backup_file] = "BACKUPS DISABLED"
			end

			pd.setMainProgress(current_case_index)
			pd.setMainStatusAndLogIt("Preparing to open case: #{case_info.getCaseDirectory}")
		end

		# How do we handle when a case seems to be locked
		case_processor.onCaseIsLocked do |locked_info|
			pd.logMessage "Case appears to be locked:"
			pd.logMessage locked_info.getCaseInfo.getLockProperties.toString
			locked_info.skipCase

			# Record our result
			result_data[locked_info.getCaseInfo.getGuid] = {
				:case_name => locked_info.getCaseInfo.getName,
				:case_directory => locked_info.getCaseInfo.getCaseDirectoryPath,
				:migration_status => "Case was locked: #{locked_info.getCaseInfo.getLockProperties.toString}",
			}
		end

		# What do we do when we open a case and an error occurs
		case_processor.onErrorOpeningCase do |error_info|
			pd.logMessage "Error opening case:"
			pd.logMessage error_info.getError.getMessage
			puts error_info.getError.getStackTrace.map{|s| s.toString}.to_a.join("\n")
			error_info.skipCase

			# Record our result
			result_data[error_info.getCaseInfo.getGuid] = {
				:case_name => error_info.getCaseInfo.getName,
				:case_directory => error_info.getCaseInfo.getCaseDirectoryPath,
				:migration_status => "Error opening case: #{error_info.getError.getMessage}",
			}
		end

		# What do we do when code ran against each case has an error
		case_processor.onUserFunctionError do |func_error|
			pd.logMessage "Error while processing case:"
			pd.logMessage func_error.getError.getMessage
			puts func_error.getError.getStackTrace.map{|s| s.toString}.to_a.join("\n")
			func_error.skipCase

			# Record our result
			result_data[func_error.getCaseInfo.getGuid] = {
				:case_name => func_error.getCaseInfo.getName,
				:case_directory => func_error.getCaseInfo.getCaseDirectoryPath,
				:migration_status => "Unexpected error: #{func_error.getError.getMessage}",
			}
		end

		pd.setMainProgress(0,case_directories.size)

		case_directories.each do |case_directory|
			pd.logMessage("Adding: #{case_directory}")
			case_processor.addCaseDirectory(case_directory)
		end

		# Case migration in Nuix is basically just opening each case, giving Nuix permission to migrate
		# the case if it deems the case needs to be migrated to a newer version to work with the
		# currently running version of Nuix.  That means we basically just make use of the bulk case
		# processor to open each case (and handle different issues above).
		case_processor.withEachCase($current_case) do |nuix_case,case_info,case_index,total_cases|
			if pd.abortWasRequested
				next false # True means process no more cases
			end

			pd.logMessage("Case opened/migrated")

			result_data[case_info.getGuid][:migration_status] = "Case Migrated"
			
			next true
		end

		# Write all the results we accumulated during processing
		# to our report CSV
		pd.logMessage("Recording results to CSV...")
		CSV.open(report_csv,"w:utf-8") do |csv|
			csv << [
				"Case Name",
				"Case Directory",
				"Status",
				"Backup File",
			]

			result_data.each do |case_guid,data|
				csv << [
					data[:case_name],
					data[:case_directory],
					data[:migration_status],
					data[:backup_file],
				]
			end
		end

		# Finalize progress dialog state
		if pd.abortWasRequested
			pd.logMessage("User Aborted")
		else
			pd.setCompleted
		end
	end
end