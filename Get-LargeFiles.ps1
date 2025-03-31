# Get-LargeFiles.ps1
# This script finds all files larger than a specified size in a directory and its subdirectories

param(
    [Parameter(Mandatory=$true)]
    [string]$SearchPath,
    
    [Parameter(Mandatory=$true)]
    [string]$MinSize,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowSizeInMB = $false
)

# Function to convert size input to bytes
function Convert-ToBytes {
    param([string]$SizeString)
    
    if ($SizeString -match "^\d+$") {
        # If just a number, assume bytes
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

# Convert the minimum size to bytes
$minSizeBytes = Convert-ToBytes -SizeString $MinSize

# Validate the search path
if (-not (Test-Path -Path $SearchPath)) {
    Write-Host "The specified path '$SearchPath' does not exist." -ForegroundColor Red
    exit
}

# Get all files recursively and filter by size
Write-Host "Searching for files larger than $MinSize in $SearchPath and its subdirectories..." -ForegroundColor Yellow
Write-Host "This may take a while for large directories..." -ForegroundColor Yellow

# Use -Force to access hidden files and directories
# Capture and handle errors without stopping the script using try/catch
$largeFiles = @()
$errorCount = 0

Get-ChildItem -Path $SearchPath -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable errors | ForEach-Object {
    try {
        if ($_.Length -gt $minSizeBytes) {
            $largeFiles += $_
        }
    }
    catch {
        # Silent error handling
    }
}

# Report on access errors
if ($errors.Count -gt 0) {
    Write-Host "Note: Some directories or files couldn't be accessed due to permission restrictions." -ForegroundColor Yellow
    Write-Host "To see all files, try running this script as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Sort the results by size descending
$largeFiles = $largeFiles | Sort-Object -Property Length -Descending

# Display results
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