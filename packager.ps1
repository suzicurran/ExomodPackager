# Assumptions we're making
[int] $EXPECTED_EXO_FILE_COUNT = 29;
[string] $GIT_FOLDER_NAME = ".git"
[string] $GIT_EXE_PATH = ".\src\PortableGit\bin\sh.exe"

# User settings, persisting between runs
[string] $settingsPath = ".\settings.json"

# Structure for temp files
[string] $hashFileName = "storiesHash"
[string] $tempFolderName = "temp"
[string] $tempPathWindows = ".\$tempFolderName\"
[string] $tempPathUnix = "./$tempFolderName/"
[string] $baseStoriesFolderName = "Stories"
[string] $moddedStoriesFolderName = "ModStories"

# Structure for output mod
[string] $outputFolderName = "outputMod"
[string] $outputFolderPathWindows = ".\$outputFolderName\"
[string] $outputFolderPathUnix = "./$outputFolderName/"

[string] $outputPatchName = "exomod.patch"
[string] $manifestFileName = "exomod_manifest.json"

class ExomodPackagerSettingsFile {
    [int] $SettingsVersion
    [string] $PathToCleanStoriesFolder
    [string] $Author
}

class ExomodPackagerManifestFile {
    [int] $ManifestVersion
    [string] $Name
    [string] $Author
    [string] $Description
    [string] $StoriesChecksum
}

function diffStoriesAndSavePatch() {
    param (
        [string] $baseExoStoriesPath = "$tempPathUnix$baseStoriesFolderName",
        [string] $modExoStoriesPath = "$tempPathUnix$moddedStoriesFolderName"
    )

    #Write-Host "base path $baseExoStoriesPath vs $modExoStoriesPath"

    [string] $outputPatchPath = "$outputFolderPathUnix$outputPatchName"
    & "$GIT_EXE_PATH" -c "git diff --no-index $baseExoStoriesPath $modExoStoriesPath > $outputPatchPath"
}

function generateMod() {

    param (
        [Parameter(Mandatory = $true)]
        [ExomodPackagerManifestFile] $manifestFile
    )

    # Create output folder
    New-Item -Path "$outputFolderPathWindows" -ItemType Directory | Out-Null

    # Generate patch
    diffStoriesAndSavePatch

    # Generate manifest
    [string] $manifestJson = ConvertTo-Json $manifestFile
    Out-File -FilePath "$outputFolderPathWindows$manifestFileName" -InputObject $manifestJson -NoClobber
}

function validateStoriesFolderPath() {
    param (
        [string] $inputExoStoriesPath
    )

    [bool] $isValidFolderPath = Test-Path -Path "$inputExoStoriesPath" -PathType Container
    if ($isValidFolderPath) {
        $matchingFiles = Get-ChildItem -Path "$inputExoStoriesPath\*" -Include "*.exo"
        if ($matchingFiles.count -ne $EXPECTED_EXO_FILE_COUNT) {
            Write-Warning "Did not find expected story files in folder. Check the provided location and try again."
            Exit 1
        }
    }
    else {
        Write-Warning "Could not validate path to stories folder. Check the provided location and try again."
        Exit 1
    }
}

function cleanUpTempFiles() {
    if (Test-Path -Path "$tempPathWindows" -PathType Container) {
        Write-Host "Cleaning up temp files..."
        Remove-Item "$tempPathWindows" -Recurse -Force
    }
}

function cleanUpOutputFiles() {
    # Check if output files already exist, and if so make sure they want to overwrite them before continuing
    if ((Test-Path -Path "$outputFolderPathWindows$manifestFileName" -PathType Leaf) -or (Test-Path -Path "$outputFolderPathWindows$outputPatchName" -PathType Leaf)) {
        Write-Warning "Output files already exist. If you continue, the existing files will be deleted."
        [string] $overwriteConfigUserInput = Read-Host -Prompt "Are you sure you want to continue? Enter 'yes' or 'no' and hit ENTER"
        Switch ($overwriteConfigUserInput) {
            "yes" { 
                Remove-Item "$outputFolderPathWindows" -Recurse -Force
                Break; 
            }
            "y" { 
                Remove-Item "$outputFolderPathWindows" -Recurse -Force
                Break;
            }
            "no" {
                Write-Host "Package creation terminated by user."
                Exit 0
            }
            "n" {
                Write-Host "Package creation terminated by user."
                Exit 0
            }
            default {
                Write-Host "Invalid input."
                Exit 1
            }
        }
    }
}

function setUpTempFiles() {
    # Clean up just in case, though this should also happen at the end of each run
    cleanUpTempFiles

    # Set up folders
    New-Item -Path "$tempPathWindows" -ItemType Directory | Out-Null

    # Copy both sets of stories over
    Copy-Item -Path $settings.PathToCleanStoriesFolder -Destination "$tempPathWindows$baseStoriesFolderName" -Recurse
    Copy-Item -Path $moddedStoriesFolderPath -Destination "$tempPathWindows$moddedStoriesFolderName" -Recurse

    # Clean up any git stuff that came with them, we don't need it
    if (Test-Path -Path "$tempPathWindows$baseStoriesFolderName\$GIT_FOLDER_NAME" -PathType Container) {
        Remove-Item "$tempPathWindows$baseStoriesFolderName\$GIT_FOLDER_NAME" -Recurse -Force
    }
    if (Test-Path -Path "$tempPathWindows$moddedStoriesFolderName\$GIT_FOLDER_NAME" -PathType Container) {
        Remove-Item "$tempPathWindows$moddedStoriesFolderName\$GIT_FOLDER_NAME" -Recurse -Force
    }
}

function getTempBaseStoriesChecksum() {
    $exoFileList = Get-ChildItem "$tempPathWindows$baseStoriesFolderName\*.exo" | Select-Object -Property Name, FullName | Sort-Object
    $exoHashes = "";
    foreach ($exoFile in $exoFileList) {
        $fileHash = (Get-FileHash $exoFile.FullName -Algorithm MD5).Hash
        $exoHashes = "$exoHashes $fileHash $($exoFile.Name)"
    }
    $tempHashFilePath = "$tempPathWindows$hashFileName"
    Out-File -FilePath "$tempHashFilePath" -InputObject $exoHashes -NoClobber
    if (Test-Path -Path "$tempHashFilePath" -PathType Leaf) {
        return (Get-FileHash -Path "$tempHashFilePath" -Algorithm MD5).Hash
    }
    else {
        Write-Warning "Failed while generating hash to validate base stories folder."
        Exit 1
    }
}

function getSettings() {
    [bool] $isSettingsFromFile = $false
    # Check if settings already exist
    if (Test-Path -Path "$settingsPath" -PathType Leaf) {
        # Load and populate settings from file
        Write-Host "Found settings.json, loading packager settings from it..."
        $settingsFileContent = ConvertFrom-Json (Get-Content -Path "$settingsPath" -Raw)
        if ($settingsFileContent.SettingsVersion -eq 1) {
            try {
                $loadedSettings = [ExomodPackagerSettingsFile]::new()
                $loadedSettings.Author = $settingsFileContent.Author
                $loadedSettings.PathToCleanStoriesFolder = $settingsFileContent.PathToCleanStoriesFolder
                Write-Host $loadedSettings.PathToCleanStoriesFolder
                validateStoriesFolderPath($loadedSettings.PathToCleanStoriesFolder)
                Write-Host "Settings loaded from file look good!"
                $isSettingsFromFile = $true
            }
            catch {
                Write-Warning "Could not parse settings file for expected values. File may be corrupt: consider deleting it and re-running packager script."
                Exit 1
            }
        }
        else {
            Write-Warning "Additional settings schema versions haven't been implemented. What are you even doing?"
            Write-Warning "Version $($isSettingsFromFile.SettingsVersion)"
            Exit 1
        }
    }

    # If not, create a new settings file and populate it
    if (!$isSettingsFromFile) {
        $newSettings = [ExomodPackagerSettingsFile]::new()
        $newSettings.Author = Read-Host -Prompt "What name would you like to author this mod under? This will be present in the manifest file distributed with the mod"
        $newSettings.PathToCleanStoriesFolder = Read-Host -Prompt "Please enter the path of your unmodified Stories directory. Example: $(${ENV:ProgramFiles(x86)})\Steam\steamapps\common\Exocolonist\Exocolonist_Data\StreamingAssets\Stories"
        validateStoriesFolderPath($newSettings.PathToCleanStoriesFolder)
        Write-Host "New packager settings look good! Saving to settings.json for future use..."

        # Save them down immediately if validated
        [string] $newSettingsJson = ConvertTo-Json $newSettings
        Out-File -FilePath ".\settings.json" -InputObject $newSettingsJson -NoClobber
    }
    if ($isSettingsFromFile) { return $loadedSettings } else { return $newSettings }
}


# ===== START =====
[ExomodPackagerSettingsFile] $settings = getSettings
[ExomodPackagerManifestFile] $manifest = [ExomodPackagerManifestFile]::new()
$manifest.Author = $settings.Author

# Prep for mod generation
cleanUpOutputFiles

# Ask for the modded Stories folder
[string] $moddedStoriesFolderPath = Read-Host -Prompt "Please enter the path to your MODDED Stories directory. Example: $(${ENV:USERPROFILE})\Documents\ModdedStories"
validateStoriesFolderPath($moddedStoriesFolderPath)

# Set up temp copies of both Stories
setUpTempFiles

# Generate checksum and prompt for other manifest values
$manifest.StoriesChecksum = getTempBaseStoriesChecksum
$manifest.Name = Read-Host -Prompt "Provide a short name for this mod"
$manifest.Description = Read-Host -Prompt "Provide a short text description for the mod"
$manifest.ManifestVersion = 1;

# Does what it says
generateMod($manifest)

cleanUpTempFiles
Write-Host -ForegroundColor Magenta "New mod created as 'outputMod' file. Rename the folder to match your mod and then share with others!"
Exit 0