@echo off
mode con cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

set "TMPFILE=%TEMP%\curl_status.tmp"

:: 清空结果文件
> 响应成功.txt (
    rem 空文件，纯网址，无标题
)
> 响应失败.txt (
    rem 空文件，纯网址，无标题
)

for /f "usebackq delims=" %%A in ("urls.txt") do (
    set "url=%%A"
    if not "!url!"=="" (
        echo 正在检测：!url!

        curl --max-time 5 -s -o nul -w "%%{http_code}" "!url!" > "!TMPFILE!" 2>nul
        set /p status=<"!TMPFILE!"
        del /f /q "!TMPFILE!" >nul

        if "!status!"=="200" (
            echo !url! >> 响应成功.txt
        ) else (
            echo !url! >> 响应失败.txt
        )
    )
)

echo ✅ 检测完成，成功和失败文件已生成。
pause
