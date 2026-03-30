@echo off
setlocal enabledelayedexpansion

set "SCRIPT_NAME=FileAnalyzer"
set "SCRIPT_VERSION=1.0.0"

if "%~1"=="" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="-v" goto :show_version
if "%~1"=="--version" goto :show_version

set "TARGET_DIR=%~1"

if not exist "%TARGET_DIR%" (
    echo [ERROR] Folder not found: %TARGET_DIR%
    exit /b 1
)

if not exist "%TARGET_DIR%\*" (
    echo [ERROR] Not a folder: %TARGET_DIR%
    exit /b 1
)

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%a"
if defined DT (
    set "DATE_STR=!DT:~0,4!-!DT:~4,2!-!DT:~6,2!"
    set "TIME_STR=!DT:~8,2!-!DT:~10,2!-!DT:~12,2!"
) else (
    for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "DATE_STR=%%a-%%b-%%c"
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "TIME_STR=%%a-%%b-00"
)

for /f %%a in ('hostname') do set "COMPUTER_NAME=%%a"

set "DESKTOP=%USERPROFILE%\Desktop"
if not exist "%DESKTOP%" set "DESKTOP=%USERPROFILE%\OneDrive\Desktop"

set "OUTPUT_FILE=%DESKTOP%\FileAnalysis_%COMPUTER_NAME%_%DATE_STR%_%TIME_STR%.txt"

echo Analyzing folder: %TARGET_DIR%
echo Please wait...

set "TOTAL_FILES=0"
set "TOTAL_SIZE=0"
set "IMAGE_COUNT=0"
set "IMAGE_SIZE=0"
set "DOC_COUNT=0"
set "DOC_SIZE=0"
set "VIDEO_COUNT=0"
set "VIDEO_SIZE=0"
set "ARCHIVE_COUNT=0"
set "ARCHIVE_SIZE=0"
set "AUDIO_COUNT=0"
set "AUDIO_SIZE=0"
set "CODE_COUNT=0"
set "CODE_SIZE=0"
set "OTHER_COUNT=0"
set "OTHER_SIZE=0"

set "TEMP_SIZES=%TEMP%\fs_%RANDOM%.tmp"
type nul > "%TEMP_SIZES%"

for /r "%TARGET_DIR%" %%f in (*) do (
    set /a TOTAL_FILES+=1
    set "FILE_SIZE=%%~zf"
    set /a TOTAL_SIZE+=FILE_SIZE
    
    set "EXT=%%~xf"
    set "EXT=!EXT:~1!"
    
    set "PAD_SIZE=000000000000000!FILE_SIZE!"
    set "PAD_SIZE=!PAD_SIZE:~-15!"
    echo !PAD_SIZE!	%%f>> "%TEMP_SIZES%"
    
    set "FILE_TYPE=OTHER"
    
    for %%e in (JPG JPEG PNG GIF BMP TIFF TIF WEBP SVG ICO PSD RAW HEIC) do (
        if /i "!EXT!"=="%%e" set "FILE_TYPE=IMAGE"
    )
    
    for %%e in (PDF DOC DOCX XLS XLSX PPT PPTX TXT RTF ODT ODS ODP MD CSV) do (
        if /i "!EXT!"=="%%e" set "FILE_TYPE=DOC"
    )
    
    for %%e in (MP4 AVI MKV MOV WMV FLV WEBM M4V MPG MPEG 3GP) do (
        if /i "!EXT!"=="%%e" set "FILE_TYPE=VIDEO"
    )
    
    for %%e in (ZIP RAR 7Z TAR GZ BZ2 XZ ISO CAB) do (
        if /i "!EXT!"=="%%e" set "FILE_TYPE=ARCHIVE"
    )
    
    for %%e in (MP3 WAV FLAC AAC OGG WMA M4A AIFF) do (
        if /i "!EXT!"=="%%e" set "FILE_TYPE=AUDIO"
    )
    
    for %%e in (JS TS PY JAVA C CPP H HPP CS GO RS PHP RB SWIFT KT SQL HTML CSS JSON XML YAML YML BAT SH PS1) do (
        if /i "!EXT!"=="%%e" set "FILE_TYPE=CODE"
    )
    
    if "!FILE_TYPE!"=="IMAGE" (
        set /a IMAGE_COUNT+=1
        set /a IMAGE_SIZE+=FILE_SIZE
    ) else if "!FILE_TYPE!"=="DOC" (
        set /a DOC_COUNT+=1
        set /a DOC_SIZE+=FILE_SIZE
    ) else if "!FILE_TYPE!"=="VIDEO" (
        set /a VIDEO_COUNT+=1
        set /a VIDEO_SIZE+=FILE_SIZE
    ) else if "!FILE_TYPE!"=="ARCHIVE" (
        set /a ARCHIVE_COUNT+=1
        set /a ARCHIVE_SIZE+=FILE_SIZE
    ) else if "!FILE_TYPE!"=="AUDIO" (
        set /a AUDIO_COUNT+=1
        set /a AUDIO_SIZE+=FILE_SIZE
    ) else if "!FILE_TYPE!"=="CODE" (
        set /a CODE_COUNT+=1
        set /a CODE_SIZE+=FILE_SIZE
    ) else (
        set /a OTHER_COUNT+=1
        set /a OTHER_SIZE+=FILE_SIZE
    )
)

call :format_size TOTAL_SIZE
set "TOTAL_SIZE_FMT=!FORMATTED_SIZE!"
call :format_size IMAGE_SIZE
set "IMAGE_SIZE_FMT=!FORMATTED_SIZE!"
call :format_size DOC_SIZE
set "DOC_SIZE_FMT=!FORMATTED_SIZE!"
call :format_size VIDEO_SIZE
set "VIDEO_SIZE_FMT=!FORMATTED_SIZE!"
call :format_size ARCHIVE_SIZE
set "ARCHIVE_SIZE_FMT=!FORMATTED_SIZE!"
call :format_size AUDIO_SIZE
set "AUDIO_SIZE_FMT=!FORMATTED_SIZE!"
call :format_size CODE_SIZE
set "CODE_SIZE_FMT=!FORMATTED_SIZE!"
call :format_size OTHER_SIZE
set "OTHER_SIZE_FMT=!FORMATTED_SIZE!"

echo ============================================================ > "%OUTPUT_FILE%"
echo                   File Analysis Report >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo Analysis Time: %DATE_STR% %TIME_STR% >> "%OUTPUT_FILE%"
echo Computer Name: %COMPUTER_NAME% >> "%OUTPUT_FILE%"
echo Target Folder: %TARGET_DIR% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo                   File Statistics Overview >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo Total Files: %TOTAL_FILES% >> "%OUTPUT_FILE%"
echo Total Size: %TOTAL_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo               File Type Classification >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo [Images] >> "%OUTPUT_FILE%"
echo   Count: %IMAGE_COUNT% >> "%OUTPUT_FILE%"
echo   Size: %IMAGE_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo [Documents] >> "%OUTPUT_FILE%"
echo   Count: %DOC_COUNT% >> "%OUTPUT_FILE%"
echo   Size: %DOC_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo [Videos] >> "%OUTPUT_FILE%"
echo   Count: %VIDEO_COUNT% >> "%OUTPUT_FILE%"
echo   Size: %VIDEO_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo [Archives] >> "%OUTPUT_FILE%"
echo   Count: %ARCHIVE_COUNT% >> "%OUTPUT_FILE%"
echo   Size: %ARCHIVE_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo [Audio] >> "%OUTPUT_FILE%"
echo   Count: %AUDIO_COUNT% >> "%OUTPUT_FILE%"
echo   Size: %AUDIO_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo [Code] >> "%OUTPUT_FILE%"
echo   Count: %CODE_COUNT% >> "%OUTPUT_FILE%"
echo   Size: %CODE_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo [Other] >> "%OUTPUT_FILE%"
echo   Count: %OTHER_COUNT% >> "%OUTPUT_FILE%"
echo   Size: %OTHER_SIZE_FMT% >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo             Top 10 Largest Files >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

set "RANK=0"
for /f "usebackq tokens=1* delims=	" %%a in (`sort /r "%TEMP_SIZES%"`) do (
    set /a RANK+=1
    if !RANK! leq 10 (
        set "PAD_SIZE=%%a"
        set "F_PATH=%%b"
        set "F_SIZE=!PAD_SIZE:~0!"
        for /f "tokens=* delims=0" %%z in ("!PAD_SIZE!") do set "F_SIZE=%%z"
        if "!F_SIZE!"=="" set "F_SIZE=0"
        call :format_size F_SIZE
        echo   !RANK!. !FORMATTED_SIZE! - !F_PATH! >> "%OUTPUT_FILE%"
    )
)

echo. >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"
echo                     Analysis Complete >> "%OUTPUT_FILE%"
echo ============================================================ >> "%OUTPUT_FILE%"

if exist "%TEMP_SIZES%" del "%TEMP_SIZES%" >nul 2>&1

echo.
echo Analysis complete!
echo Report saved to: %OUTPUT_FILE%
echo.

exit /b 0

:format_size
set "SIZE_BYTES=!%1!"
set "FORMATTED_SIZE="
if !SIZE_BYTES! geq 1073741824 (
    set /a SIZE_GB=SIZE_BYTES/1073741824
    set /a SIZE_REM=SIZE_BYTES%%1073741824*100/1073741824
    set "FORMATTED_SIZE=!SIZE_GB!.!SIZE_REM! GB"
) else if !SIZE_BYTES! geq 1048576 (
    set /a SIZE_MB=SIZE_BYTES/1048576
    set /a SIZE_REM=SIZE_BYTES%%1048576*100/1048576
    set "FORMATTED_SIZE=!SIZE_MB!.!SIZE_REM! MB"
) else if !SIZE_BYTES! geq 1024 (
    set /a SIZE_KB=SIZE_BYTES/1024
    set /a SIZE_REM=SIZE_BYTES%%1024*100/1024
    set "FORMATTED_SIZE=!SIZE_KB!.!SIZE_REM! KB"
) else (
    set "FORMATTED_SIZE=!SIZE_BYTES! Bytes"
)
exit /b

:show_help
echo.
echo Usage: %~nx0 [options] folder_path
echo.
echo Options:
echo   -h, --help      Show this help message
echo   -v, --version   Show version information
echo.
echo Examples:
echo   %~nx0 "C:\Users\Documents"
echo   %~nx0 D:\Downloads
echo.
echo Features:
echo   1. Scan all files in the specified folder
echo   2. Classify files by type (Images, Documents, Videos, Archives, etc.)
echo   3. List top 10 largest files
echo   4. Generate report to Desktop
echo.
exit /b 0

:show_version
echo %SCRIPT_NAME% version %SCRIPT_VERSION%
exit /b 0
