<#
.SYNOPSIS
    Gathers information about website posts to build a dynamic map.html file.

.DESCRIPTION
    This script is designed to be run as part of a larger deployment process
    (e.g., by a main deployment script). It scans a specified content directory
    for individual post folders, reads their 'index.md' files to extract
    metadata (coordinates, title, distance, grade), normalizes the title
    for URL generation, and then constructs JavaScript snippets for map popups.
    Finally, it injects these popups and a count into a 'map_template.html'
    and saves the result as 'map.html' in the static output directory.

.PARAMETER DebugMode
    Enables verbose debug messages during script execution.

.EXAMPLE
    .\build_map.ps1
    Runs the script in normal mode.

.EXAMPLE
    .\build_map.ps1 -DebugMode
    Runs the script with verbose debug output.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [switch]$DebugMode
)

# --- Configuration ---
$root_dir = "C:\code\dartmoorwalking" # Where the Hugo project root is
$map_template_path = Join-Path $root_dir "scripts\map_template.html" # Path to the HTML template
$map_output_path = Join-Path $root_dir "static\map.html" # Where to output the final map.html
$posts_content_dir = Join-Path $root_dir "content\post" # Where the posts content is
$url_prefix = "https://dartmoorwalking.org/p/" # What to prepend to the normalized title for URLs

# --- Global Variables ---
$popup_string = "" # Accumulates the JavaScript popup code
$good_hits = 0     # Counter for successfully processed posts
$bad_hits = 0      # Counter for posts that failed parsing

# --- Helper Function for Debugging ---
function Write-DebugMessage {
    param (
        [string]$Message
    )
    if ($DebugMode) {
        Write-Host "DEBUG: $Message" -ForegroundColor DarkGray
    }
}

Write-DebugMessage "Script started with DebugMode: $DebugMode"
Write-DebugMessage "Root directory: $root_dir"
Write-DebugMessage "Posts content directory: $posts_content_dir"

# --- Get Post Directories ---
Write-Host "`nScanning for post directories in: $posts_content_dir" -ForegroundColor Green
$postsdirs = @()
try {
    $postsdirs = Get-ChildItem -Path $posts_content_dir -Directory | Where-Object { $_.Name -ne ".wrangler" } | Select-Object -ExpandProperty Name
    Write-Host "Found $($postsdirs.Count) post directories." -ForegroundColor Green
    Write-DebugMessage "Post directories found: $($postsdirs -join ', ')"
}
catch {
    Write-Error "Failed to list directories in $posts_content_dir. Error: $($_.Exception.Message)"
    exit 1 # Critical error, cannot proceed without posts
}

# --- Function to Normalize Title ---
function Convert-ToLowercaseDash {
    param (
        [string]$InputString
    )
    # Convert to lowercase
    $normalizedString = $InputString.ToLower()

    # Replace non-alphabetic characters with dashes
    $normalizedString = $normalizedString -replace '[^a-z]', '-'

    # Remove consecutive dashes
    $normalizedString = $normalizedString -replace '-+', '-'

    # Remove leading and trailing dashes
    $normalizedString = $normalizedString -replace '^-|-$', ''

    return $normalizedString
}

# --- Process Each Post ---
Write-Host "`nProcessing individual posts..." -ForegroundColor Green
foreach ($dirName in $postsdirs) {
    $indexPath = Join-Path $posts_content_dir "$dirName\index.md"

    if (Test-Path -Path $indexPath -PathType Leaf) {
        Write-DebugMessage "Found index.md at $indexPath"

        try {
            $file_content = Get-Content -Path $indexPath -Raw -Encoding UTF8 # Assume UTF8 for markdown
        }
        catch {
            Write-Warning "Could not read file $indexPath. Skipping. Error: $($_.Exception.Message)"
            $bad_hits++
            continue
        }

        # Initialize variables for current post
        $coords = $null
        $title = $null
        $distance = $null
        $grade = $null
        $url = $null

        # Parse metadata using regex
        # PowerShell's -match operator populates the $matches automatic variable
        if ($file_content -match 'coords: (.*)') { $coords = $matches[1].Trim() }
        if ($file_content -match 'title: (.*)') { $title = $matches[1].Trim() }
        if ($file_content -match 'distance: (.*)') { $distance = $matches[1].Trim() }
        if ($file_content -match 'grade: (.*)') { $grade = $matches[1].Trim().ToLower() }

        # Remove single quotes from title (Perl's s/'//g equivalent)
        if ($title) {
            $title = $title -replace "'", ""
        }

        # Normalize title and construct URL
        $normalised_title = ""
        if ($title) {
            $normalised_title = Convert-ToLowercaseDash -InputString $title
            $url = $url_prefix + $normalised_title + '/'
        }

        Write-DebugMessage "Parsed title: `"$title`" normalised to: ($normalised_title)"
        Write-DebugMessage "URL: $url"

        # Check for incomplete data
        if (-not $title -or -not $distance -or -not $grade -or -not $coords -or -not $url) {
            Write-Warning "Incomplete data for post in directory '$dirName', skipping this popup."
            Write-Warning "(Title='$title', Distance='$distance', Grade='$grade', Coords='$coords', URL='$url')"
            $bad_hits++
            continue
        }

        # Build popup string
        # Example: const marker1 = L.marker([50.579587, -3.797581]).addTo(map) .bindPopup('<a href="https://dartmoorwalking.org/p/yes-tor-via-row-tor/" target="_parent">Yes Tor, via Row Tor</a><br />A gentle 3 mile walk.');
        $good_hits++
        $popup_string += "const marker$good_hits = L.marker([$coords]).addTo(map) .bindPopup('<a href=`"$url`" target=`"_parent`">$title</a><br />A $grade $distance mile walk.');`n"
        Write-Host "POPUP added: $title" -ForegroundColor DarkGreen
    }
    else {
        Write-DebugMessage "No index.md found in post directory: $dirName at $indexPath"
    }
}

# --- Build Map HTML ---
Write-Host "`nBuilding map HTML file..." -ForegroundColor Green

$map_code = ""
try {
    $map_code = Get-Content -Path $map_template_path -Raw -Encoding UTF8
}
catch {
    Write-Error "Cannot open map template file at $map_template_path. Error: $($_.Exception.Message)"
    exit 1 # Critical error
}

# Replace placeholders
$map_code = $map_code -replace 'FORM_POPUPS', $popup_string
$map_code = $map_code -replace 'FORM_NUMMAPS', $good_hits

# Write out the final map.html
try {
    Set-Content -Path $map_output_path -Value $map_code -Encoding UTF8 -Force
    Write-Host "Map built successfully at $map_output_path." -ForegroundColor Green
}
catch {
    Write-Error "Failed to write map output file to $map_output_path. Error: $($_.Exception.Message)"
    exit 1 # Critical error
}

Write-Host "`nMap build complete. $good_hits popups created. $bad_hits posts failed parsing." -ForegroundColor Cyan
