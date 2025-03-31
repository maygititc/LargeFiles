# Get-LargeFiles.ps1
#
# This PowerShell script finds all files larger than a specified size in a directory and its subdirectories.
# It supports size input in bytes, KB, MB, GB, or TB.
#
# Usage:
#   .\Get-LargeFiles.ps1 -SearchPath <directory_path> -MinSize <size> [-ShowSizeInMB]
#
# Parameters:
#   SearchPath: Mandatory. The directory path where the search should begin.
#   MinSize: Mandatory. The minimum file size to search for. Accepts a number followed by KB, MB, GB, or TB (e.g., 10MB).
#   ShowSizeInMB: Optional. If specified, displays file sizes in MB.
#
# Examples:
#   .\Get-LargeFiles.ps1 -SearchPath "C:\Users\Example" -MinSize "10MB"
#   .\Get-LargeFiles.ps1 -SearchPath "D:\Data" -MinSize "1GB" -ShowSizeInMB
#
# Notes:
#   - Ensure you have appropriate permissions to access all directories and files
#   - Run as Administrator if you encounter permission errors
#   - Script handles errors silently and notifies of inaccessible files/directories
#
# Error Handling:
#   - Invalid paths will terminate script with message
#   - Invalid size formats will prompt error and terminate
#
# License: Provided as-is without warranty. Use at own risk.

param(
    [Parameter(Mandatory=$true)]
    [string]$SearchPath,

    [Parameter(Mandatory=$true)]
    [string]$MinSize,

    [Parameter(Mandatory=$false)]
    [switch]$ShowSizeInMB = $false
)

function Convert-ToBytes {
    param([string]$SizeString)

    if ($SizeString -match "^\d+$") {
        return [long]$SizeString
    }
    elseif ($SizeString -match "^(\d+)(KB|MB|GB|TB)$") {
        $value = [long]$Matches[1]
        $unit = $Matches[2]

        switch ($unit) {
            "KB" { return $value * 1KB }
            "MB" { return $value * 1MB }
            "GB" { return $value * 1GB }
            "TB" { return $value * 1TB }
            default { return $value }
        }
    }
    else {
        Write-Host "Invalid size format. Use a number followed by KB, MB, GB, or TB (e.g., 10MB)" -ForegroundColor Red
        exit
    }
}

$minSizeBytes = Convert-ToBytes -SizeString $MinSize

if (-not (Test-Path -Path $SearchPath)) {
    Write-Host "The specified path '$SearchPath' does not exist." -ForegroundColor Red
    exit
}

Write-Host "Searching for files larger than $MinSize in $SearchPath and its subdirectories..." -ForegroundColor Yellow
Write-Host "This may take a while for large directories..." -ForegroundColor Yellow

$largeFiles = @()
$errorCount = 0

Get-ChildItem -Path $SearchPath -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable errors | ForEach-Object {
    try {
        if ($_.Length -gt $minSizeBytes) {
            $largeFiles += $_
        }
    }
    catch {
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Note: Some directories or files couldn't be accessed due to permission restrictions." -ForegroundColor Yellow
    Write-Host "To see all files, try running this script as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

$largeFiles = $largeFiles | Sort-Object -Property Length -Descending

if ($largeFiles.Count -eq 0) {
    Write-Host "No files larger than $MinSize were found." -ForegroundColor Green
}
else {
    Write-Host "Found $($largeFiles.Count) files larger than $MinSize :" -ForegroundColor Green

    foreach ($file in $largeFiles) {
        if ($ShowSizeInMB) {
            $sizeInMB = [math]::Round($file.Length / 1MB, 2)
            Write-Host "$($file.FullName) - $sizeInMB MB"
        }
        elseif ($file.Length -ge 1GB) {
            $sizeInGB = [math]::Round($file.Length / 1GB, 2)
            Write-Host "$($file.FullName) - $sizeInGB GB"
        }
        elseif ($file.Length -ge 1MB) {
            $sizeInMB = [math]::Round($file.Length / 1MB, 2)
            Write-Host "$($file.FullName) - $sizeInMB MB"
        }
        else {
            $sizeInKB = [math]::Round($file.Length / 1KB, 2)
            Write-Host "$($file.FullName) - $sizeInKB KB"
        }
    }
}