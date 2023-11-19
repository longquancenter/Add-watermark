@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

REM Prompt user for source directory
set /p "source_dir=Source file directory (default is current directory): "
if not defined source_dir set "source_dir=."

REM Prompt user for watermark files directory
set /p "watermark_dir=The watermark directory (default is current directory): "
if not defined watermark_dir set "watermark_dir=.\wtm"

REM Prompt user for output directory name
set /p "output_dir_name=Output directory name (default is 'output'): "
if not defined output_dir_name set "output_dir_name=output"

REM Set configurable parameters
set "watermark1=!watermark_dir!\logo.png"
set "watermark2=!watermark_dir!\jinqiu.png"
set "output_dir=%source_dir%\!output_dir_name!"
set "file_extension=jpg"  REM Change the file extension as needed
set "scale_factor1=0.6"
set "left_offset1=0.03"
set "right_offset1=0.03"
set "scale_factor2=0.65"
set "offset_x2=0.04"
set "offset_y2=0.04"

REM Call functions
call :CheckFileExistence "!watermark1!"
call :CheckFileExistence "!watermark2!"
call :ProcessImagesWithWatermark1
call :ProcessImagesWithWatermark2

REM 列出所有输出的文件名和目录位置
echo 输出的文件名和目录位置：
dir /b /s "%output_dir%"

REM 删除中间处理的文件
del "%output_dir%\*_up_Left.%file_extension%"
del "%output_dir%\*_up_Right.%file_extension%"

REM 等待用户按任意键才关闭窗口
pause
goto :EOF

:ProcessImagesWithWatermark1
REM Process images with watermark1...
if not exist "%output_dir%" mkdir "%output_dir%"

for %%i in ("%source_dir%\*.%file_extension%") do (
    set "input=%%i"
    set "output_left=%output_dir%\%%~ni_up_Left.%file_extension%"
    set "output_right=%output_dir%\%%~ni_up_Right.%file_extension%"
    
    ffmpeg -i "!input!" -i "!watermark1!" -filter_complex "[1]scale=iw/%scale_factor1%:-1[wm];[0][wm]overlay=(main_w*%left_offset1%):(main_h*%left_offset1%)" "!output_left!"
    
    ffmpeg -i "!input!" -i "!watermark1!" -filter_complex "[1]scale=iw/%scale_factor1%:-1[wm];[0][wm]overlay=main_w-(main_w*%right_offset1%)-w:(main_h*%right_offset1%)" "!output_right!"
)

goto :EOF

:ProcessImagesWithWatermark2
REM Process images with watermark2...
if not exist "%output_dir%\*.%file_extension%" (
    echo 错误：output目录下没有 %file_extension% 文件
    pause
    goto :EOF
)

for %%i in ("%output_dir%\*.%file_extension%") do (
    set "input=%%i"
    set "output_left=%output_dir%\%%~ni_B_Left.%file_extension%"
    set "output_right=%output_dir%\%%~ni_B_Right.%file_extension%"

    ffmpeg -i "!input!" -i "!watermark2!" -filter_complex "[1]scale=iw/%scale_factor2%:-1[wm];[0][wm]overlay=(main_w*%offset_x2%):(main_h-(main_h*%offset_y2%)-h)" "!output_left!"
    
    ffmpeg -i "!input!" -i "!watermark2!" -filter_complex "[1]scale=iw/%scale_factor2%:-1[wm];[0][wm]overlay=main_w-(main_w*%offset_x2%)-w:(main_h-(main_h*%offset_y2%)-h)" "!output_right!"
)

goto :EOF

:CheckFileExistence
if not exist "%~1" (
    echo 错误：找不到水印文件 "%~1"
    pause
    goto :EOF
)
goto :EOF
