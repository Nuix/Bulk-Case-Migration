Bulk Case Migration
===================

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0) ![This script was last tested in Nuix 9.6](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-9.6-green.svg)

View the GitHub project [here](https://github.com/Nuix/Bulk-Case-Migration) or download the latest release [here](https://github.com/Nuix/Bulk-Case-Migration/releases).

# Overview

**Written By:** Jason Wells

**Note**: While this script is similar to the script [Case Migration Script](https://github.com/Nuix/Case-Migration-Script), that script is much older and simpler.  This script is more advanced and should generally be considered a replacement for that script.  The one benefit that other script has over this one is that it has no JAR dependencies.

This script migrates a list of Nuix cases to the version of Nuix running the script (as necessary).  This script is the automated equivalent of opening each case one by one in Nuix Workstation (the GUI) and allowing Nuix to migrate a case whenever it prompted you to do so.

The script opens each case via the API, giving Nuix permission to migrate the case as necessary.  This is done by providing a value of `true` for the setting `migrate` when opening the case via [CaseFactory.open](https://download.nuix.com/releases/desktop/stable/docs/en/scripting/api/nuix/CaseFactory.html#open-java.io.File-java.util.Map-):

**migrate**: *If the case requires migration and this parameter is set to true, migrates the case if required, otherwise an exception occurs and the script will terminate. Migration occurs silently in the console.*

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

# Usage

| Tab | Setting | Description |
|-----|---------|-------------|
| **Main** | **Report CSV** | Specifies the CSV file to record migration results to. |
| **Main** | **Search Sub-Directories** | When checked, the script will search the provided directories and their sub-directories for cases.  When checked, it is expected that each provided directory contains 1 Nuix case at the root of that directory. |
| **Main** | **Add Directories** button | Shows a directory chooser which you can use to add 1 or more directories to the list of directories to be processed. |
| **Main** | **Import** button | Shows a file chooser allowing you to pick a text file to import.  The text file is expected to have 1 directory per line. |
| **Main** | **Remove Selected** button | Removes selected directories from the list. |
| **Backups** | **Create Backups** | When checked, the script will make a backup of each case before attempting to open/migrate it.  Backups are created by archiving the contents of a given case directory as a Zip file. |
| **Backups** | **Backups Directory** | Directory that the script will create backup archives in. |
| **Backups** | **Compression** | The compression level to use when creating case backup archive Zips.  A compression level of `0` will just pack the data into the Zip without any compression (fastest) while a compression level of `9` will attempt to compress the case data as much as it can (slowest). |

# Cloning this Repository

**Note**: If you are downloading a release from the [releases](https://github.com/Nuix/Bulk-Case-Migration/releases) section, you *DO NOT* need to download these files separately as they should already be present in the release archive you download!

This script relies on code from [Nx](https://github.com/Nuix/Nx) to present a settings dialog and progress dialog.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of Nx.jar by either:
1. Building it from [the source](https://github.com/Nuix/Nx)
2. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/Nx/releases)

Once you have a copy of Nx.jar, make sure to include it in the same directory as the script.

This script also relies on code from [SuperUtilities](https://github.com/Nuix/SuperUtilities).  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of SuperUtilities.jar by either:
1. Building it from [the source](https://github.com/Nuix/SuperUtilities)
2. Downloading an already built JAR file from the [SuperUtilities releases](https://github.com/Nuix/SuperUtilities/releases)

Once you also have a copy of SuperUtilities.jar, make sure to include it in the same directory as the script.

# License

```
Copyright 2022 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
