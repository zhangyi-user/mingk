<#
.SYNOPSIS
File Analyzer Tool - Scan folder, classify by file type, list large files, generate report

.DESCRIPTION
This script scans specified folder, classifies files by type, finds top 10 largest files,
and saves analysis report to desktop.

.PARAMETER FolderPath
Folder path to scan, default is current directory

.EXAMPLE
.\FileAnalyzer.ps1 -FolderPath "C:\Users\Documents"

.EXAMPLE
.\FileAnalyzer.ps1
#>

param(
    [string]$FolderPath = (Get-Location).Path
)

# Define file type categories
$fileTypes = @{
    'Images'      = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.svg', '.webp', '.ico')
    'Documents'   = @('.doc', '.docx', '.pdf', '.txt', '.xls', '.xlsx', '.ppt', '.pptx', '.csv', '.xml', '.json', '.md', '.rtf')
    'Videos'      = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.mpeg', '.mpg', '.webm')
    'Audio'       = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a')
    'Archives'    = @('.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.iso')
    'Executables' = @('.exe', '.msi', '.bat', '.cmd', '.com', '.ps1')
    'Code'        = @('.cs', '.java', '.py', '.js', '.html', '.css', '.cpp', '.c', '.h', '.php', '.go', '.rs', '.ts')
}

# Format file size function
function Format-FileSize {
    param([double]$Size)
    $units = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    $unitIndex = 0
    while ($Size -ge 1024 -and $unitIndex -lt $units.Count - 1) {
        $Size /= 1024
        $unitIndex++
    }
    return [string]::Format("{0:N2} {1}", $Size, $units[$unitIndex])
}

# Get file type category
function Get-FileTypeCategory {
    param([string]$Extension)
    $ext = $Extension.ToLower()
    foreach ($category in $fileTypes.Keys) {
        if ($fileTypes[$category] -contains $ext) {
            return $category
        }
    }
    return 'Others'
}

# Main program
Write-Host "========================================"
Write-Host "          File Analyzer v1.0"
Write-Host "========================================"
Write-Host ""
Write-Host "Scanning folder: $FolderPath"
Write-Host "This may take some time, please wait..."
Write-Host ""

try {
    # Validate folder path
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Error: Folder path does not exist - $FolderPath"
        exit 1
    }

    # Get all files
    $allFiles = Get-ChildItem -Path $FolderPath -File -Recurse -ErrorAction SilentlyContinue
    
    if ($allFiles.Count -eq 0) {
        Write-Host "Warning: No files found in this folder"
        exit 0
    }

    Write-Host "Total files found: $($allFiles.Count)"
    Write-Host ""

    # Statistics by file type
    Write-Host "Calculating file type statistics..."
    $typeStats = @{}
    foreach ($file in $allFiles) {
        $category = Get-FileTypeCategory -Extension $file.Extension
        if (-not $typeStats.ContainsKey($category)) {
            $typeStats[$category] = @{
                Count = 0
                TotalSize = 0
            }
        }
        $typeStats[$category].Count++
        $typeStats[$category].TotalSize += $file.Length
    }

    # Calculate total size
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum

    # Find top 10 largest files
    Write-Host "Finding top 10 largest files..."
    $top10Files = $allFiles | Sort-Object -Property Length -Descending | Select-Object -First 10

    Write-Host ""
    Write-Host "========================================"
    Write-Host "           Summary Results"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Total files: $($allFiles.Count)"
    Write-Host "Total size: $(Format-FileSize -Size $totalSize)"
    Write-Host ""

    # Display type statistics
    Write-Host "File Type Statistics:"
    Write-Host "----------------------------------------"
    foreach ($category in $typeStats.Keys | Sort-Object) {
        $stats = $typeStats[$category]
        $percentage = [math]::Round(($stats.TotalSize / $totalSize) * 100, 2)
        Write-Host ("{0}: {1} files, total size {2} ({3}%)" -f $category.PadRight(12), $stats.Count.ToString().PadLeft(5), (Format-FileSize -Size $stats.TotalSize).PadLeft(12), $percentage)
    }

    Write-Host ""
    Write-Host "Top 10 Largest Files:"
    Write-Host "----------------------------------------"
    $rank = 1
    foreach ($file in $top10Files) {
        Write-Host ("{0,2}. {1} - {2}" -f $rank, (Format-FileSize -Size $file.Length).PadLeft(12), $file.FullName)
        $rank++
    }

    # Generate report to desktop
    Write-Host ""
    Write-Host "Generating analysis report..."
    
    $computerName = $env:COMPUTERNAME
    $dateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFileName = "FileAnalysis_${computerName}_${dateTime}.txt"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $reportPath = Join-Path -Path $desktopPath -ChildPath $reportFileName

    # Build report content
    $reportContent = @()
    $reportContent += "========================================"
    $reportContent += "          File Analysis Report"
    $reportContent += "========================================"
    $reportContent += ""
    $reportContent += "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $reportContent += "Computer Name: $computerName"
    $reportContent += "Scanned Folder: $FolderPath"
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "           Summary"
    $reportContent += "========================================"
    $reportContent += ""
    $reportContent += "Total files: $($allFiles.Count)"
    $reportContent += "Total size: $(Format-FileSize -Size $totalSize)"
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "         File Type Statistics"
    $reportContent += "========================================"
    $reportContent += ""
    foreach ($category in $typeStats.Keys | Sort-Object) {
        $stats = $typeStats[$category]
        $percentage = [math]::Round(($stats.TotalSize / $totalSize) * 100, 2)
        $reportContent += ("{0}: {1} files, total size {2} ({3}%)" -f $category.PadRight(12), $stats.Count.ToString().PadLeft(5), (Format-FileSize -Size $stats.TotalSize).PadLeft(12), $percentage)
    }
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "       Top 10 Largest Files"
    $reportContent += "========================================"
    $reportContent += ""
    $rank = 1
    foreach ($file in $top10Files) {
        $reportContent += ("{0,2}. {1} - {2}" -f $rank, (Format-FileSize -Size $file.Length).PadLeft(12), $file.FullName)
        $rank++
    }
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "         End of Report"
    $reportContent += "========================================"

    # Write report file
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Host ""
    Write-Host "Report generated successfully!"
    Write-Host "Report path: $reportPath"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "          Analysis Complete!"
    Write-Host "========================================"

}
catch {
    Write-Error "Error occurred: $_"
    exit 1
}
