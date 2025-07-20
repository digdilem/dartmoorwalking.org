<#
.SYNOPSIS
    Deploys the dartmoorwalking website by building Hugo,
    cleaning GPX files, and creating a GPX zip archive.

.DESCRIPTION
    This script automates the deployment process for the dartmoorwalking website.
    It performs the following steps:
    1. Changes the current directory to the Hugo project root.
    2. Builds the Hugo website, cleaning the destination directory and minifying output.
    3. Navigates to the GPX files directory.
    4. Replaces specific extraneous strings within all GPX files.
    5. Deletes any existing GPX zip archive.
    6. Creates a new GPX zip archive containing all GPX and TXT files.

.NOTES
    - Ensure Hugo is installed and accessible in your system's PATH.
    - Ensure 7-Zip is installed at "C:\Program Files\7-Zip\7z.exe".
    - Run this script from a PowerShell prompt.
#>

# Define base paths for clarity and easier modification
$hugoProjectRoot = "C:\code\dartmoorwalking"
$gpxDirectory = Join-Path $hugoProjectRoot "static\gpx"
$zipFilePath = Join-Path (Join-Path $hugoProjectRoot "static") "dartmoorwalking.org-gpxfiles.zip"
$sevenZipExecutable = "C:\Program Files\7-Zip\7z.exe"

Write-Host "Starting deployment for dartmoorwalking..." -ForegroundColor Cyan



# --- Step 3: Remove extraneous strings from GPX files ---
Write-Host "`nRemoving extraneous strings from GPX files in: $gpxDirectory" -ForegroundColor Green

# Navigate to the GPX directory for file operations
try {
    Set-Location -Path $gpxDirectory
    Write-Host "Successfully changed directory to GPX folder." -ForegroundColor Green
}
catch {
    Write-Error "Failed to change directory to $gpxDirectory. GPX file processing skipped."
    # Do not exit, as this might not be a critical failure for the entire deploy
}

# Define the replacements as a hash table for easier management
$replacements = @{
    "Geocaching Map Enhancements v0.8.2" = "dartmoorwalking.org"
    "GME Export" = "dartmoorwalking.org"
    "Route file exported from Geocaching.com using Geocaching Map Enhancements." = "Route file exported from dartmoorwalking.org - please see the corresponding web page for this walk"
    "Geocaching.com user" = "Simon Avery"
}

# Process all GPX files with the defined replacements
try {
    Get-ChildItem -Path $gpxDirectory -Filter "*.gpx" | ForEach-Object {
        $filePath = $_.FullName
        Write-Host "Processing file: $($_.Name)" -ForegroundColor DarkGray

        $content = Get-Content -Path $filePath -Raw # -Raw reads entire file as single string
        $originalContent = $content # Keep original to check if changes were made

        foreach ($oldString in $replacements.Keys) {
            $newString = $replacements[$oldString]
            # Using -replace operator for case-insensitive replacement by default
            # For case-sensitive, use $content = $content.Replace($oldString, $newString)
            $content = $content -replace [regex]::Escape($oldString), $newString
        }

        # Only write back if content has actually changed to avoid unnecessary file writes
        if ($content -ne $originalContent) {
            Set-Content -Path $filePath -Value $content -Force # -Force overwrites existing file
            Write-Host "  - Replacements applied to $($_.Name)" -ForegroundColor DarkGreen
        } else {
            Write-Host "  - No replacements needed for $($_.Name)" -ForegroundColor DarkYellow
        }
    }
    Write-Host "GPX file string replacement completed." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during GPX file string replacement: $($_.Exception.Message)"
    # Do not exit, continue to next steps if possible
}


# --- Step 4: Build GPX zipfile ---
Write-Host "`nBuilding GPX zipfile: $zipFilePath" -ForegroundColor Green

# Ensure we are in the GPX directory for 7-Zip to find files easily
# This 'cd' is redundant if the previous step succeeded, but ensures context for 7-Zip
try {
    Set-Location -Path $gpxDirectory
}
catch {
    Write-Error "Failed to change directory to $gpxDirectory for zip creation. Zip file may not be created correctly."
    # Continue, but the 7-Zip command might fail
}

# Delete existing zip file if it exists
if (Test-Path -Path $zipFilePath) {
    Write-Host "Deleting existing zip file: $zipFilePath" -ForegroundColor Yellow
    try {
        Remove-Item -Path $zipFilePath -Force
        Write-Host "Existing zip file deleted." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to delete existing zip file: $($_.Exception.Message). Continuing anyway."
    }
} else {
    Write-Host "No existing zip file found at $zipFilePath." -ForegroundColor DarkYellow
}

# Create the new zip file using 7-Zip
# Ensure 7-Zip is installed at the specified path.
Write-Host "Creating new zip file..." -ForegroundColor Green
try {
    # The 'a' command adds files to an archive.
    # The last arguments are the files to add (relative to current directory)
    & "$sevenZipExecutable" a "$zipFilePath" "*.gpx" "*.txt"
    Write-Host "GPX zipfile created successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to create GPX zipfile. Please ensure 7-Zip is installed at '$sevenZipExecutable' and the paths are correct. Error: $($_.Exception.Message)"
    exit 1 # Exit script on critical error
}


# Build maps page
cd \code\dartmoorwalking\scripts
.\build_map.ps1





# --- Step 1: Navigate to Hugo project root ---
Write-Host "`nNavigating to Hugo project root: $hugoProjectRoot" -ForegroundColor Green
try {
    Set-Location -Path $hugoProjectRoot
    Write-Host "Successfully changed directory." -ForegroundColor Green
}
catch {
    Write-Error "Failed to change directory to $hugoProjectRoot. Please ensure the path is correct."
    exit 1 # Exit script on critical error
}


# --- Step 2: Build Hugo website ---
Write-Host "`nBuilding Hugo website..." -ForegroundColor Green
try {
    # Execute Hugo build command.
    # The '--cleanDestinationDir' flag removes existing files before building.
    # The '--minify' flag minifies HTML, CSS, JS, etc.
    hugo build --cleanDestinationDir --minify
    Write-Host "Hugo build completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "Hugo build failed. Please check Hugo installation and project configuration."
    exit 1 # Exit script on critical error
}



git add .
git commit -am "Updating to reflect development"
git push -f origin main

npx wrangler pages deploy c:\code\digdilem\public --project-name=digdilem25  --commit-dirty=true



Write-Host "`nDeployment script finished." -ForegroundColor Cyan
