@echo off
REM 设置代码页为UTF-8
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

REM 设置ffmpeg可执行文件的名称和下载链接
set "ffmpeg_executable=ffmpeg.exe"
set "ffmpeg_download_url=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

REM 检测是否已安装ffmpeg
where %ffmpeg_executable%
if %errorlevel% neq 0 (
    echo 未找到 %ffmpeg_executable% 可执行文件。尝试下载并使用。

    REM 下载ffmpeg压缩包
    bitsadmin /transfer download_ffmpeg /priority normal %ffmpeg_download_url% ffmpeg-release-essentials.zip
    
    REM 等待下载完成
    bitsadmin /complete download_ffmpeg
    
    REM 解压缩ffmpeg压缩包
    powershell Expand-Archive -Path .\ffmpeg-release-essentials.zip -DestinationPath .
    
    REM 将ffmpeg.exe移动到脚本目录
    move .\ffmpeg-*\bin\ffmpeg.exe .\
    
    REM 删除下载的文件和解压缩的文件夹
    del ffmpeg-release-essentials.zip
    rmdir /s /q ffmpeg-*
    
    REM 再次检测是否已安装
    where %ffmpeg_executable%
    if %errorlevel% neq 0 (
        echo 下载失败，请手动安装 %ffmpeg_executable%。
        pause
        exit /b 1
    )
)

REM 提示用户输入源文件目录
set /p "source_dir=源文件目录（默认为当前目录）: "
if not defined source_dir set "source_dir=."

REM 提示用户输入水印文件目录
set /p "watermark_dir=水印文件目录（默认为当前目录下的wtm文件夹）: "
if not defined watermark_dir set "watermark_dir=.\wtm"

REM 提示用户输入输出目录名称
set /p "output_dir_name=输出目录名称（默认为'output'）: "
if not defined output_dir_name set "output_dir_name=output"

REM 设置可配置的参数
set "watermark1=!watermark_dir!\logo.png"
set "watermark2=!watermark_dir!\jinqiu.png"
set "output_dir=%source_dir%\!output_dir_name!"
set "file_extension=jpg"  REM 根据需要更改文件扩展名
set "scale_factor1=0.6"
set "left_offset1=0.03"
set "right_offset1=0.03"
set "scale_factor2=0.65"
set "offset_x2=0.04"
set "offset_y2=0.04"

REM 调用函数
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
REM 处理带有水印1的图像...
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
REM 处理带有水印2的图像...
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
