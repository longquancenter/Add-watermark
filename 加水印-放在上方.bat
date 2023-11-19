@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

set "watermark=wtm\logo.png"
set "output_dir=output"
mkdir "%output_dir%" 2>nul

REM 检查水印文件是否存在，如果不存在则停止执行
if not exist "!watermark!" (
    echo 错误：找不到水印文件 "!watermark!"
    pause
    goto :EOF
)

REM 检查目录中是否存在 jpg 文件，如果不存在则停止执行
set "jpg_exists="
for %%j in (*.jpg) do (
    set "jpg_exists=1"
    goto :ContinueLoop
)
if not defined jpg_exists (
    echo 错误：目录下没有 jpg 文件
    pause
    goto :EOF
)

:ContinueLoop

REM 参数设置区域
set "scale_factor=0.6"
set "left_offset=0.03"
set "right_offset=0.03"

for %%i in (*.jpg) do (
    set "input=%%i"
    
    REM 设置左边水印输出路径
    set "output_left=%output_dir%\%%~ni_output_Left.jpg"
    ffmpeg -i "!input!" -i "!watermark!" -filter_complex "[1]scale=iw/%scale_factor%:-1[wm];[0][wm]overlay=(main_w*%left_offset%):(main_h*%left_offset%)" "!output_left!"
    
    REM 设置右边水印输出路径
    set "output_right=%output_dir%\%%~ni_output_Right.jpg"
    ffmpeg -i "!input!" -i "!watermark!" -filter_complex "[1]scale=iw/%scale_factor%:-1[wm];[0][wm]overlay=main_w-(main_w*%right_offset%)-w:(main_h*%right_offset%)" "!output_right!"
)

REM 列出所有输出的文件名和目录位置
echo 输出的文件名和目录位置：
dir /b /s "%output_dir%"

REM 等待用户按任意键才关闭窗口
pause
