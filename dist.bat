@echo off
echo EBG Distribution Tool (for Windows)

:lovepath
echo If your Love2D executable is in "C:\Program Files\LOVE", type "skip" and press enter. Otherwise type the path to your Love2D folder (not the executable!).
set /p input=path:
if %input% == "" goto lovepath
if "%input%" == "skip" (
    set LOVE2D_PATH=C:\Program Files\LOVE
) else (
    set LOVE2D_PATH=%input%
)
goto distribute

:distribute
copy /b "%LOVE2D_PATH%\love.exe"+%1 "ebg-nightfox.exe"

echo Distribution ended.
pause