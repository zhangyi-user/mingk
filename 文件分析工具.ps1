<#
.SYNOPSIS
文件分析工具 - 扫描指定文件夹，按文件类型分类统计，列出大文件，生成分析报告

.DESCRIPTION
这个脚本可以扫描指定文件夹，按文件类型分类统计，找出占用空间最大的前10个文件，
并将分析报告保存到桌面。

.PARAMETER FolderPath
要扫描的文件夹路径，默认为当前目录

.EXAMPLE
.\文件分析工具.ps1 -FolderPath "C:\Users\Documents"

.EXAMPLE
.\文件分析工具.ps1
#>

param(
    [string]$FolderPath = (Get-Location).Path
)

# 定义文件类型分类
$fileTypes = @{
    ''图片''        = @(''.jpg'', ''.jpeg'', ''.png'', ''.gif'', ''.bmp'', ''.tiff'', ''.svg'', ''.webp'', ''.ico'')
    ''文档''        = @(''.doc'', ''.docx'', ''.pdf'', ''.txt'', ''.xls'', ''.xlsx'', ''.ppt'', ''.pptx'', ''.csv'', ''.xml'', ''.json'', ''.md'', ''.rtf'')
    ''视频''        = @(''.mp4'', ''.avi'', ''.mkv'', ''.mov'', ''.wmv'', ''.flv'', ''.mpeg'', ''.mpg'', ''.webm'')
    ''音频''        = @(''.mp3'', ''.wav'', ''.flac'', ''.aac'', ''.ogg'', ''.wma'', ''.m4a'')
    ''压缩包''      = @(''.zip'', ''.rar'', ''.7z'', ''.tar'', ''.gz'', ''.bz2'', ''.xz'', ''.iso'')
    ''可执行文件''  = @(''.exe'', ''.msi'', ''.bat'', ''.cmd'', ''.com'', ''.ps1'')
    ''代码文件''    = @(''.cs'', ''.java'', ''.py'', ''.js'', ''.html'', ''.css'', ''.cpp'', ''.c'', ''.h'', ''.php'', ''.go'', ''.rs'', ''.ts'')
}

# 格式化字节大小函数
function Format-FileSize {
    param([double]$Size)
    $units = @(''B'', ''KB'', ''MB'', ''GB'', ''TB'', ''PB'')
    $unitIndex = 0
    while ($Size -ge 1024 -and $unitIndex -lt $units.Count - 1) {
        $Size /= 1024
        $unitIndex++
    }
    return [string]::Format("{0:N2} {1}", $Size, $units[$unitIndex])
}

# 获取文件类型分类
function Get-FileTypeCategory {
    param([string]$Extension)
    $ext = $Extension.ToLower()
    foreach ($category in $fileTypes.Keys) {
        if ($fileTypes[$category] -contains $ext) {
            return $category
        }
    }
    return ''其他''
}

# 主程序
Write-Host "========================================"
Write-Host "          文件分析工具 v1.0"
Write-Host "========================================"
Write-Host ""
Write-Host "正在扫描文件夹: $FolderPath"
Write-Host "这可能需要一些时间，请稍候..."
Write-Host ""

try {
    # 验证文件夹路径
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "错误: 文件夹路径不存在 - $FolderPath"
        exit 1
    }

    # 获取所有文件
    $allFiles = Get-ChildItem -Path $FolderPath -File -Recurse -ErrorAction SilentlyContinue
    
    if ($allFiles.Count -eq 0) {
        Write-Host "警告: 该文件夹内没有找到任何文件"
        exit 0
    }

    Write-Host "找到文件总数: $($allFiles.Count) 个"
    Write-Host ""

    # 按文件类型分类统计
    Write-Host "正在按文件类型统计..."
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

    # 计算总大小
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum

    # 找出前10大文件
    Write-Host "正在找出最大的10个文件..."
    $top10Files = $allFiles | Sort-Object -Property Length -Descending | Select-Object -First 10

    Write-Host ""
    Write-Host "========================================"
    Write-Host "           统计结果摘要"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "文件总数: $($allFiles.Count) 个"
    Write-Host "总占用空间: $(Format-FileSize -Size $totalSize)"
    Write-Host ""

    # 显示类型统计
    Write-Host "文件类型统计:"
    Write-Host "----------------------------------------"
    foreach ($category in $typeStats.Keys | Sort-Object) {
        $stats = $typeStats[$category]
        $percentage = [math]::Round(($stats.TotalSize / $totalSize) * 100, 2)
        Write-Host ("{0}: {1} 个文件，总大小 {2} (占比 {3}%)" -f $category.PadRight(8), $stats.Count.ToString().PadLeft(5), (Format-FileSize -Size $stats.TotalSize).PadLeft(12), $percentage)
    }

    Write-Host ""
    Write-Host "占用空间最大的前10个文件:"
    Write-Host "----------------------------------------"
    $rank = 1
    foreach ($file in $top10Files) {
        Write-Host ("{0,2}. {1} - {2}" -f $rank, (Format-FileSize -Size $file.Length).PadLeft(12), $file.FullName)
        $rank++
    }

    # 生成报告到桌面
    Write-Host ""
    Write-Host "正在生成分析报告..."
    
    $computerName = $env:COMPUTERNAME
    $dateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFileName = "文件分析_${computerName}_${dateTime}.txt"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $reportPath = Join-Path -Path $desktopPath -ChildPath $reportFileName

    # 构建报告内容
    $reportContent = @()
    $reportContent += "========================================"
    $reportContent += "          文件分析报告"
    $reportContent += "========================================"
    $reportContent += ""
    $reportContent += "生成时间: $(Get-Date -Format ''yyyy年MM月dd日 HH:mm:ss'')"
    $reportContent += "计算机名: $computerName"
    $reportContent += "扫描目录: $FolderPath"
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "           统计概览"
    $reportContent += "========================================"
    $reportContent += ""
    $reportContent += "文件总数: $($allFiles.Count) 个"
    $reportContent += "总占用空间: $(Format-FileSize -Size $totalSize)"
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "         文件类型详细统计"
    $reportContent += "========================================"
    $reportContent += ""
    foreach ($category in $typeStats.Keys | Sort-Object) {
        $stats = $typeStats[$category]
        $percentage = [math]::Round(($stats.TotalSize / $totalSize) * 100, 2)
        $reportContent += ("{0}: {1} 个文件，总大小 {2} (占比 {3}%)" -f $category.PadRight(8), $stats.Count.ToString().PadLeft(5), (Format-FileSize -Size $stats.TotalSize).PadLeft(12), $percentage)
    }
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "       占用空间最大的前10个文件"
    $reportContent += "========================================"
    $reportContent += ""
    $rank = 1
    foreach ($file in $top10Files) {
        $reportContent += ("{0,2}. {1} - {2}" -f $rank, (Format-FileSize -Size $file.Length).PadLeft(12), $file.FullName)
        $rank++
    }
    $reportContent += ""
    $reportContent += "========================================"
    $reportContent += "         报告结束"
    $reportContent += "========================================"

    # 写入报告文件
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Host ""
    Write-Host "报告已成功生成!"
    Write-Host "报告路径: $reportPath"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "          分析完成!"
    Write-Host "========================================"

}
catch {
    Write-Error "发生错误: $_"
    exit 1
}