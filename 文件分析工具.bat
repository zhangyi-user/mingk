@echo off
chcp 65001 > nul
echo ========================================
echo           文件分析工具 v1.0
echo ========================================
echo.
set /p "folder=请输入要扫描的文件夹路径 (直接回车使用当前目录): "
if "%folder%"=="" set "folder=%cd%"
echo.
echo 正在扫描文件夹: %folder%
echo 这可能需要一些时间，请稍候...
echo.
powershell.exe -ExecutionPolicy Bypass -Command "
\$fileTypes = @{
    '图片'        = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.svg', '.webp', '.ico')
    '文档'        = @('.doc', '.docx', '.pdf', '.txt', '.xls', '.xlsx', '.ppt', '.pptx', '.csv', '.xml', '.json', '.md', '.rtf')
    '视频'        = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.mpeg', '.mpg', '.webm')
    '音频'        = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a')
    '压缩包'      = @('.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.iso')
    '可执行文件'  = @('.exe', '.msi', '.bat', '.cmd', '.com', '.ps1')
    '代码文件'    = @('.cs', '.java', '.py', '.js', '.html', '.css', '.cpp', '.c', '.h', '.php', '.go', '.rs', '.ts')
}
function Format-FileSize {
    param([double]\$Size)
    \$units = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    \$unitIndex = 0
    while (\$Size -ge 1024 -and \$unitIndex -lt \$units.Count - 1) {
        \$Size /= 1024
        \$unitIndex++
    }
    return [string]::Format('{0:N2} {1}', \$Size, \$units[\$unitIndex])
}
function Get-FileTypeCategory {
    param([string]\$Extension)
    \$ext = \$Extension.ToLower()
    foreach (\$category in \$fileTypes.Keys) {
        if (\$fileTypes[\$category] -contains \$ext) {
            return \$category
        }
    }
    return '其他'
}
\$FolderPath = '%folder%'
if (-not (Test-Path -Path \$FolderPath -PathType Container)) {
    Write-Host '错误: 文件夹路径不存在 - ' \$FolderPath
    exit 1
}
\$allFiles = Get-ChildItem -Path \$FolderPath -File -Recurse -ErrorAction SilentlyContinue
if (\$allFiles.Count -eq 0) {
    Write-Host '警告: 该文件夹内没有找到任何文件'
    exit 0
}
Write-Host '找到文件总数: ' \$allFiles.Count ' 个'
Write-Host ''
Write-Host '正在按文件类型统计...'
\$typeStats = @{}
foreach (\$file in \$allFiles) {
    \$category = Get-FileTypeCategory -Extension \$file.Extension
    if (-not \$typeStats.ContainsKey(\$category)) {
        \$typeStats[\$category] = @{
            Count = 0
            TotalSize = 0
        }
    }
    \$typeStats[\$category].Count++
    \$typeStats[\$category].TotalSize += \$file.Length
}
\$totalSize = (\$allFiles | Measure-Object -Property Length -Sum).Sum
Write-Host '正在找出最大的10个文件...'
\$top10Files = \$allFiles | Sort-Object -Property Length -Descending | Select-Object -First 10
Write-Host ''
Write-Host '========================================'
Write-Host '           统计结果摘要'
Write-Host '========================================'
Write-Host ''
Write-Host '文件总数: ' \$allFiles.Count ' 个'
Write-Host '总占用空间: ' (Format-FileSize -Size \$totalSize)
Write-Host ''
Write-Host '文件类型统计:'
Write-Host '----------------------------------------'
foreach (\$category in \$typeStats.Keys | Sort-Object) {
    \$stats = \$typeStats[\$category]
    \$percentage = [math]::Round((\$stats.TotalSize / \$totalSize) * 100, 2)
    Write-Host ('{0}: {1} 个文件，总大小 {2} (占比 {3}%)' -f \$category.PadRight(8), \$stats.Count.ToString().PadLeft(5), (Format-FileSize -Size \$stats.TotalSize).PadLeft(12), \$percentage)
}
Write-Host ''
Write-Host '占用空间最大的前10个文件:'
Write-Host '----------------------------------------'
\$rank = 1
foreach (\$file in \$top10Files) {
    Write-Host ('{0,2}. {1} - {2}' -f \$rank, (Format-FileSize -Size \$file.Length).PadLeft(12), \$file.FullName)
    \$rank++
}
Write-Host ''
Write-Host '正在生成分析报告...'
\$computerName = \$env:COMPUTERNAME
\$dateTime = Get-Date -Format 'yyyyMMdd_HHmmss'
\$reportFileName = '文件分析_' + \$computerName + '_' + \$dateTime + '.txt'
\$desktopPath = [Environment]::GetFolderPath('Desktop')
\$reportPath = Join-Path -Path \$desktopPath -ChildPath \$reportFileName
\$reportContent = @()
\$reportContent += '========================================'
\$reportContent += '          文件分析报告'
\$reportContent += '========================================'
\$reportContent += ''
\$reportContent += '生成时间: ' + (Get-Date -Format 'yyyy年MM月dd日 HH:mm:ss')
\$reportContent += '计算机名: ' + \$computerName
\$reportContent += '扫描目录: ' + \$FolderPath
\$reportContent += ''
\$reportContent += '========================================'
\$reportContent += '           统计概览'
\$reportContent += '========================================'
\$reportContent += ''
\$reportContent += '文件总数: ' + \$allFiles.Count + ' 个'
\$reportContent += '总占用空间: ' + (Format-FileSize -Size \$totalSize)
\$reportContent += ''
\$reportContent += '========================================'
\$reportContent += '         文件类型详细统计'
\$reportContent += '========================================'
\$reportContent += ''
foreach (\$category in \$typeStats.Keys | Sort-Object) {
    \$stats = \$typeStats[\$category]
    \$percentage = [math]::Round((\$stats.TotalSize / \$totalSize) * 100, 2)
    \$reportContent += ('{0}: {1} 个文件，总大小 {2} (占比 {3}%)' -f \$category.PadRight(8), \$stats.Count.ToString().PadLeft(5), (Format-FileSize -Size \$stats.TotalSize).PadLeft(12), \$percentage)
}
\$reportContent += ''
\$reportContent += '========================================'
\$reportContent += '       占用空间最大的前10个文件'
\$reportContent += '========================================'
\$reportContent += ''
\$rank = 1
foreach (\$file in \$top10Files) {
    \$reportContent += ('{0,2}. {1} - {2}' -f \$rank, (Format-FileSize -Size \$file.Length).PadLeft(12), \$file.FullName)
    \$rank++
}
\$reportContent += ''
\$reportContent += '========================================'
\$reportContent += '         报告结束'
\$reportContent += '========================================'
\$reportContent | Out-File -FilePath \$reportPath -Encoding UTF8
Write-Host ''
Write-Host '报告已成功生成!'
Write-Host '报告路径: ' \$reportPath
Write-Host ''
Write-Host '========================================'
Write-Host '          分析完成!'
Write-Host '========================================'
"
echo.
pause
