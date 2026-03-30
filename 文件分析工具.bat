@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: 文件分析工具 - Windows批处理版
:: 功能：
::   1. 扫描指定文件夹内的所有文件
::   2. 按文件类型自动分类统计
::   3. 列出占用空间最大的前10个文件
::   4. 生成整理报告到桌面
:: ============================================

:: 设置标题
title 文件分析工具

:: 初始化变量
set "targetFolder="
set "reportFile="
set "tempFile=%TEMP%\file_analysis_temp.txt"

:: 获取计算机名
for /f "tokens=*" %%a in ('hostname') do set "computerName=%%a"

:: 获取日期时间 (使用WMIC获取，兼容所有区域设置)
for /f "tokens=2 delims==." %%a in ('wmic os get localdatetime /value ^| find "="') do (
    set "dt=%%a"
    set "yyyy=!dt:~0,4!"
    set "mm=!dt:~4,2!"
    set "dd=!dt:~6,2!"
    set "hh=!dt:~8,2!"
    set "min=!dt:~10,2!"
    set "ss=!dt:~12,2!"
)
set "dateTime=!yyyy!!mm!!dd!_!hh!!min!!ss!"

:: 设置桌面路径
set "desktopPath=%USERPROFILE%\Desktop"

:: 清屏并显示欢迎信息
cls
echo ============================================
echo           文 件 分 析 工 具
echo ============================================
echo.

:: 获取目标文件夹路径
if "%~1"=="" (
    echo 请拖入要分析的文件夹，或直接输入路径：
    set /p "targetFolder=文件夹路径: "
) else (
    set "targetFolder=%~1"
)

:: 去除可能存在的引号
set "targetFolder=!targetFolder:"=!"

:: 验证路径
if not exist "!targetFolder!" (
    echo [错误] 指定的路径不存在: !targetFolder!
    pause
    exit /b 1
)

if not exist "!targetFolder!\*" (
    echo [错误] 指定的路径不是文件夹或为空: !targetFolder!
    pause
    exit /b 1
)

echo.
echo [信息] 正在分析文件夹: !targetFolder!
echo [信息] 请稍候，这可能需要一些时间...
echo.

:: 设置报告文件名
set "reportFile=%desktopPath%\文件分析_%computerName%_%dateTime%.txt"

:: 删除临时文件（如果存在）
if exist "%tempFile%" del "%tempFile%" 2>nul

:: ============================================
:: 扫描所有文件并收集信息
:: ============================================
set "totalFiles=0"
set "totalSize=0"

echo [步骤 1/3] 正在扫描文件...

:: 递归扫描所有文件
for /r "!targetFolder!" %%F in (*.*) do (
    if exist "%%F" (
        set /a totalFiles+=1
        set "fileSize=%%~zF"
        set "fileExt=%%~xF"
        
        :: 将扩展名转为小写
        set "fileExtLower=!fileExt!"
        set "fileExtLower=!fileExtLower:A=a!"
        set "fileExtLower=!fileExtLower:B=b!"
        set "fileExtLower=!fileExtLower:C=c!"
        set "fileExtLower=!fileExtLower:D=d!"
        set "fileExtLower=!fileExtLower:E=e!"
        set "fileExtLower=!fileExtLower:F=f!"
        set "fileExtLower=!fileExtLower:G=g!"
        set "fileExtLower=!fileExtLower:H=h!"
        set "fileExtLower=!fileExtLower:I=i!"
        set "fileExtLower=!fileExtLower:J=j!"
        set "fileExtLower=!fileExtLower:K=k!"
        set "fileExtLower=!fileExtLower:L=l!"
        set "fileExtLower=!fileExtLower:M=m!"
        set "fileExtLower=!fileExtLower:N=n!"
        set "fileExtLower=!fileExtLower:O=o!"
        set "fileExtLower=!fileExtLower:P=p!"
        set "fileExtLower=!fileExtLower:Q=q!"
        set "fileExtLower=!fileExtLower:R=r!"
        set "fileExtLower=!fileExtLower:S=s!"
        set "fileExtLower=!fileExtLower:T=t!"
        set "fileExtLower=!fileExtLower:U=u!"
        set "fileExtLower=!fileExtLower:V=v!"
        set "fileExtLower=!fileExtLower:W=w!"
        set "fileExtLower=!fileExtLower:X=x!"
        set "fileExtLower=!fileExtLower:Y=y!"
        set "fileExtLower=!fileExtLower:Z=z!"
        
        :: 累加总大小
        set /a totalSize+=fileSize
        
        :: 记录文件信息到临时文件（大小|路径|扩展名）
        echo !fileSize!|%%F|!fileExtLower! >> "%tempFile%"
    )
)

if %totalFiles%==0 (
    echo [警告] 未找到任何文件！
    pause
    exit /b 0
)

echo [步骤 2/3] 正在分类统计...

:: 初始化各类文件计数和大小
set "imageCount=0" & set "imageSize=0"
set "docCount=0" & set "docSize=0"
set "videoCount=0" & set "videoSize=0"
set "audioCount=0" & set "audioSize=0"
set "zipCount=0" & set "zipSize=0"
set "codeCount=0" & set "codeSize=0"
set "exeCount=0" & set "exeSize=0"
set "otherCount=0" & set "otherSize=0"

:: 读取临时文件进行分类统计
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%tempFile%") do (
    set "fSize=%%a"
    set "fExt=%%c"
    set "found=0"
    
    :: 检查图片类型
    for %%E in (.jpg .jpeg .png .gif .bmp .webp .ico .svg .tif .tiff .raw .psd .ai) do (
        if "!fExt!"=="%%E" (
            set /a imageCount+=1
            set /a imageSize+=fSize
            set "found=1"
        )
    )
    
    :: 检查文档类型
    if !found!==0 (
        for %%E in (.txt .doc .docx .pdf .xls .xlsx .ppt .pptx .csv .md .rtf .odt .ods .odp) do (
            if "!fExt!"=="%%E" (
                set /a docCount+=1
                set /a docSize+=fSize
                set "found=1"
            )
        )
    )
    
    :: 检查视频类型
    if !found!==0 (
        for %%E in (.mp4 .avi .mkv .mov .wmv .flv .webm .m4v .mpg .mpeg .3gp .ts .m2ts) do (
            if "!fExt!"=="%%E" (
                set /a videoCount+=1
                set /a videoSize+=fSize
                set "found=1"
            )
        )
    )
    
    :: 检查音频类型
    if !found!==0 (
        for %%E in (.mp3 .wav .flac .aac .ogg .wma .m4a .opus .aiff .ape) do (
            if "!fExt!"=="%%E" (
                set /a audioCount+=1
                set /a audioSize+=fSize
                set "found=1"
            )
        )
    )
    
    :: 检查压缩包类型
    if !found!==0 (
        for %%E in (.zip .rar .7z .tar .gz .bz2 .xz .cab .iso .dmg) do (
            if "!fExt!"=="%%E" (
                set /a zipCount+=1
                set /a zipSize+=fSize
                set "found=1"
            )
        )
    )
    
    :: 检查代码类型
    if !found!==0 (
        for %%E in (.c .cpp .h .hpp .java .py .js .ts .html .css .php .go .rs .swift .kt .cs .vb .sql .json .xml .yaml .yml .sh .bat .ps1) do (
            if "!fExt!"=="%%E" (
                set /a codeCount+=1
                set /a codeSize+=fSize
                set "found=1"
            )
        )
    )
    
    :: 检查可执行文件类型
    if !found!==0 (
        for %%E in (.exe .msi .dll .sys .drv .com) do (
            if "!fExt!"=="%%E" (
                set /a exeCount+=1
                set /a exeSize+=fSize
                set "found=1"
            )
        )
    )
    
    :: 其他类型
    if !found!==0 (
        set /a otherCount+=1
        set /a otherSize+=fSize
    )
)

echo [步骤 3/3] 正在生成报告...

:: ============================================
:: 生成报告 - 先计算所有格式化后的大小
:: ============================================
call :FormatSize %totalSize%
set "totalSizeFmt=!formattedSize!"

if %imageCount% gtr 0 (
    call :FormatSize %imageSize%
    set "imageSizeFmt=!formattedSize!"
)
if %docCount% gtr 0 (
    call :FormatSize %docSize%
    set "docSizeFmt=!formattedSize!"
)
if %videoCount% gtr 0 (
    call :FormatSize %videoSize%
    set "videoSizeFmt=!formattedSize!"
)
if %audioCount% gtr 0 (
    call :FormatSize %audioSize%
    set "audioSizeFmt=!formattedSize!"
)
if %zipCount% gtr 0 (
    call :FormatSize %zipSize%
    set "zipSizeFmt=!formattedSize!"
)
if %codeCount% gtr 0 (
    call :FormatSize %codeSize%
    set "codeSizeFmt=!formattedSize!"
)
if %exeCount% gtr 0 (
    call :FormatSize %exeSize%
    set "exeSizeFmt=!formattedSize!"
)
if %otherCount% gtr 0 (
    call :FormatSize %otherSize%
    set "otherSizeFmt=!formattedSize!"
)

:: 写入报告头部
(
echo ============================================
echo           文 件 分 析 报 告
echo ============================================
echo.
echo 生成时间: %date% %time%
echo 计算机名: %computerName%
echo 分析路径: %targetFolder%
echo.
echo --------------------------------------------
echo              概 览 统 计
echo --------------------------------------------
echo 文件总数: %totalFiles% 个
echo 总占用空间: %totalSizeFmt%
echo.
echo --------------------------------------------
echo            按类型分类统计
echo --------------------------------------------
) > "%reportFile%"

:: 输出各类文件统计
if %imageCount% gtr 0 echo 图片文件: %imageCount% 个 ^(%imageSizeFmt%^) >> "%reportFile%"
if %docCount% gtr 0 echo 文档文件: %docCount% 个 ^(%docSizeFmt%^) >> "%reportFile%"
if %videoCount% gtr 0 echo 视频文件: %videoCount% 个 ^(%videoSizeFmt%^) >> "%reportFile%"
if %audioCount% gtr 0 echo 音频文件: %audioCount% 个 ^(%audioSizeFmt%^) >> "%reportFile%"
if %zipCount% gtr 0 echo 压缩包: %zipCount% 个 ^(%zipSizeFmt%^) >> "%reportFile%"
if %codeCount% gtr 0 echo 代码文件: %codeCount% 个 ^(%codeSizeFmt%^) >> "%reportFile%"
if %exeCount% gtr 0 echo 可执行文件: %exeCount% 个 ^(%exeSizeFmt%^) >> "%reportFile%"
if %otherCount% gtr 0 echo 其他文件: %otherCount% 个 ^(%otherSizeFmt%^) >> "%reportFile%"

(
echo.
echo --------------------------------------------
echo        占用空间最大的前10个文件
echo --------------------------------------------
) >> "%reportFile%"

:: 排序并输出前10个最大文件
set "rank=0"
for /f "usebackq tokens=1,* delims=|" %%a in (`type "%tempFile%" ^| sort /r`) do (
    set /a rank+=1
    if !rank! leq 10 (
        set "fSize=%%a"
        set "fPath=%%b"
        call :FormatSize !fSize!
        echo !rank!. [!formattedSize!] !fPath! >> "%reportFile%"
    ) else (
        goto :EndReport
    )
)

:EndReport
(
echo.
echo --------------------------------------------
echo              报 告 结 束
echo --------------------------------------------
) >> "%reportFile%"

:: 清理临时文件
if exist "%tempFile%" del "%tempFile%" 2>nul

:: 显示完成信息
echo.
echo ============================================
echo           分 析 完 成
echo ============================================
echo.
echo 文件总数: %totalFiles% 个
echo 总占用空间: %totalSizeFmt%
echo.
echo 报告已保存至:
echo %reportFile%
echo.

:: 验证报告文件是否生成
if exist "%reportFile%" (
    echo [成功] 报告文件已生成！
    
    :: 询问是否打开报告
    choice /C YN /N /M "是否立即打开报告？(Y/N) "
    if %errorlevel%==1 (
        start "" "%reportFile%"
    )
) else (
    echo [错误] 报告文件未能生成，请检查权限！
    pause
)

exit /b 0

:: ============================================
:: 子程序：格式化文件大小
:: ============================================
:FormatSize
set "size=%~1"
if %size% lss 1024 (
    set "formattedSize=%size% B"
) else if %size% lss 1048576 (
    set /a "kb=size/1024"
    set "formattedSize=!kb! KB"
) else if %size% lss 1073741824 (
    set /a "mb=size/1048576"
    set "formattedSize=!mb! MB"
) else (
    set /a "gb=size/1073741824"
    set "formattedSize=!gb! GB"
)
exit /b 0
