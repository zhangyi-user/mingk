# File Analyzer Tool
# Function: Scan folder, categorize files, list largest files, generate report

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = (Get-Location),
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Show help information
function Show-Help {
    Write-Host @"
========================================
        File Analyzer Tool v1.0
========================================

Usage: .\FileAnalyzer.ps1 [parameters]

Parameters:
  -Path <folder path>   Specify folder to scan (default: current directory)
  -Help                 Show help information

Examples:
  .\FileAnalyzer.ps1
  .\FileAnalyzer.ps1 -Path "C:\Users\Documents"
  .\FileAnalyzer.ps1 -Path "D:\Downloads"

Features:
  1. Scan all files in specified folder
  2. Auto categorize by file type (Images, Documents, Videos, Archives, etc.)
  3. List top 10 largest files
  4. Generate report to Desktop

========================================
"@
}

# Show help
if ($Help) {
    Show-Help
    exit 0
}

# Validate path
if (-not (Test-Path -Path $Path)) {
    Write-Error "Error: Specified path does not exist: $Path"
    exit 1
}

Write-Host "Analyzing folder: $Path" -ForegroundColor Cyan
Write-Host "Please wait..." -ForegroundColor Yellow

# Define file type categories
$FileCategories = @{
    "Images" = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp", ".svg", ".ico", ".raw", ".cr2", ".nef", ".heic")
    "Documents" = @(".doc", ".docx", ".pdf", ".txt", ".rtf", ".odt", ".xls", ".xlsx", ".ppt", ".pptx", ".csv", ".md", ".epub", ".mobi")
    "Videos" = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpg", ".mpeg", ".3gp", ".ts", ".m2ts")
    "Audio" = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a", ".opus", ".aiff", ".ape")
    "Archives" = @(".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".tgz", ".bz2", ".cab", ".iso")
    "Programs" = @(".exe", ".msi", ".bat", ".cmd", ".ps1", ".vbs", ".js", ".jar", ".dll", ".sys", ".com")
    "Code" = @(".c", ".cpp", ".h", ".hpp", ".cs", ".java", ".py", ".js", ".ts", ".html", ".css", ".php", ".go", ".rs", ".swift", ".rb", ".pl", ".sh", ".json", ".xml", ".yaml", ".yml", ".sql")
}

# Format file size function
function Format-FileSize {
    param([long]$Size)
    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    return "$Size B"
}

# Get all files
$AllFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue

if ($AllFiles.Count -eq 0) {
    Write-Warning "No files found in specified path"
    exit 0
}

Write-Host "Found $($AllFiles.Count) files, analyzing..." -ForegroundColor Green

# Initialize category statistics
$CategoryStats = @{}
$CategorySizes = @{}
foreach ($Category in $FileCategories.Keys) {
    $CategoryStats[$Category] = 0
    $CategorySizes[$Category] = 0
}
$CategoryStats["Others"] = 0
$CategorySizes["Others"] = 0

# Analyze each file
$FileList = @()
foreach ($File in $AllFiles) {
    $Extension = $File.Extension.ToLower()
    $Size = $File.Length
    $Category = "Others"
    
    # Determine file category
    foreach ($Cat in $FileCategories.Keys) {
        if ($FileCategories[$Cat] -contains $Extension) {
            $Category = $Cat
            break
        }
    }
    
    # Update statistics
    $CategoryStats[$Category]++
    $CategorySizes[$Category] += $Size
    
    # Add to file list
    $FileList += [PSCustomObject]@{
        Name = $File.Name
        FullPath = $File.FullName
        Size = $Size
        SizeFormatted = Format-FileSize $Size
        Extension = $Extension
        Category = $Category
        LastWriteTime = $File.LastWriteTime
    }
}

# Calculate total size
$TotalSize = ($AllFiles | Measure-Object -Property Length -Sum).Sum

# Get top 10 largest files
$Top10Files = $FileList | Sort-Object -Property Size -Descending | Select-Object -First 10

# Generate report filename
$ComputerName = $env:COMPUTERNAME
$DateTime = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFileName = "FileAnalysis_${ComputerName}_${DateTime}.txt"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ReportPath = Join-Path $DesktopPath $ReportFileName

# Build report content
$ReportLines = @()
$ReportLines += "================================================================================"
$ReportLines += "                           FILE ANALYSIS REPORT                                 "
$ReportLines += "================================================================================"
$ReportLines += ""
$ReportLines += "Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
$ReportLines += "Computer:  $ComputerName"
$ReportLines += "Path:      $Path"
$ReportLines += "Report:    $ReportFileName"
$ReportLines += ""
$ReportLines += "================================================================================"
$ReportLines += "                         1. GENERAL STATISTICS                                  "
$ReportLines += "================================================================================"
$ReportLines += ""
$ReportLines += "  Total Files:  $($AllFiles.Count.ToString("N0"))"
$ReportLines += "  Total Size:   $(Format-FileSize $TotalSize)"
$ReportLines += ""
$ReportLines += "================================================================================"
$ReportLines += "                         2. FILE TYPE STATISTICS                               "
$ReportLines += "================================================================================"
$ReportLines += ""

# Add category statistics
$SortedCategories = $CategoryStats.GetEnumerator() | 
    Where-Object { $_.Value -gt 0 } |
    Sort-Object -Property @{Expression={$CategorySizes[$_.Key]}; Descending=$true}

foreach ($Cat in $SortedCategories) {
    $CategoryName = $Cat.Key
    $FileCount = $Cat.Value
    $CategorySize = $CategorySizes[$CategoryName]
    $Percentage = if ($TotalSize -gt 0) { ($CategorySize / $TotalSize) * 100 } else { 0 }
    
    $ReportLines += "  {0,-12} : {1,8} files  |  {2,12}  |  {3,6:N2}%" -f 
        $CategoryName, $FileCount, (Format-FileSize $CategorySize), $Percentage
}

$ReportLines += ""
$ReportLines += "================================================================================"
$ReportLines += "                      3. TOP 10 LARGEST FILES                                   "
$ReportLines += "================================================================================"
$ReportLines += ""

# Add top 10 largest files
$Rank = 1
foreach ($File in $Top10Files) {
    $ReportLines += "  Rank $Rank"
    $ReportLines += "    Name:     $($File.Name)"
    $ReportLines += "    Path:     $($File.FullPath)"
    $ReportLines += "    Size:     $($File.SizeFormatted)"
    $ReportLines += "    Category: $($File.Category)"
    $ReportLines += "    Modified: $($File.LastWriteTime)"
    $ReportLines += ""
    $Rank++
}

$ReportLines += "================================================================================"
$ReportLines += "                         4. FILE EXTENSION DETAILS                              "
$ReportLines += "================================================================================"
$ReportLines += ""

# Statistics by extension
$ExtensionStats = $FileList | Group-Object -Property Extension | 
    Select-Object Name, @{N="Count";E={$_.Count}}, @{N="Size";E={($_.Group | Measure-Object -Property Size -Sum).Sum}} |
    Sort-Object -Property Size -Descending

foreach ($Ext in $ExtensionStats | Select-Object -First 20) {
    $ReportLines += "  {0,-10} : {1,6} files  |  {2,12}" -f 
        $Ext.Name, $Ext.Count, (Format-FileSize $Ext.Size)
}

$ReportLines += ""
$ReportLines += "================================================================================"
$ReportLines += "                              END OF REPORT                                     "
$ReportLines += "================================================================================"
$ReportLines += ""
$ReportLines += "Generated by: File Analyzer Tool v1.0"

# Save report
$ReportLines | Out-File -FilePath $ReportPath -Encoding UTF8

# Display summary in console
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     FILE ANALYSIS COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "General Statistics:" -ForegroundColor Yellow
Write-Host "  Total Files: $($AllFiles.Count.ToString("N0"))"
Write-Host "  Total Size:  $(Format-FileSize $TotalSize)"
Write-Host ""
Write-Host "File Type Statistics:" -ForegroundColor Yellow
foreach ($Cat in $SortedCategories | Select-Object -First 6) {
    $CategoryName = $Cat.Key
    $FileCount = $Cat.Value
    $CategorySize = $CategorySizes[$CategoryName]
    Write-Host "  $CategoryName : $FileCount files ($(Format-FileSize $CategorySize))"
}
Write-Host ""
Write-Host "Top 5 Largest Files:" -ForegroundColor Yellow
$DisplayRank = 1
foreach ($File in $Top10Files | Select-Object -First 5) {
    Write-Host "  $DisplayRank. $($File.Name) ($($File.SizeFormatted))"
    $DisplayRank++
}
Write-Host ""
Write-Host "Report saved to:" -ForegroundColor Green
Write-Host "  $ReportPath" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
