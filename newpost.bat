@echo off
setlocal

:: --- Configuration ---
:: Set the base directory for your Hugo project.
:: IMPORTANT: Use full path and ensure it's correct.
set "HUGOPROJECT_DIR=C:\code\dartmoorwalking"

:: --- Argument Handling ---
:: Check if the first argument (section) is provided
if "%~1"=="" (
    echo.
    echo Error: Missing section argument.
    echo Usage: %~nx0 date-post
    echo Example: %~nx0 yyyy-mm-dd
    echo.
    goto :eof
)

:: Assign arguments to more descriptive variables, removing any surrounding quotes
set "SECTION=post"
set "CONTENT_NAME=%~2"

:: --- Directory Navigation ---
:: Use pushd to change to the project directory safely.
:: It automatically handles drive changes and saves the original directory.
pushd "%HUGOPROJECT_DIR%"
if %errorlevel% neq 0 (
    echo.
    echo Error: Could not navigate to "%HUGOPROJECT_DIR%".
    echo Please ensure the path is correct and accessible.
    echo.
    goto :eof
)

:: --- Hugo Command Execution ---
echo.
echo Attempting to create new Hugo content:
echo Section: %SECTION%
echo Content Name: %CONTENT_NAME%
echo Path: content\%SECTION%\%CONTENT_NAME%\_index.md
echo.

:: Execute the Hugo command with proper quoting for paths that might contain spaces
hugo new "%SECTION%/%CONTENT_NAME%/_index.md"
if %errorlevel% neq 0 (
    echo.
    echo Error: Hugo command failed with exit code %errorlevel%.
    echo Please check Hugo's output above for details.
    echo.
) else (
    echo.
    echo Successfully created new content.
    echo.
)

:: --- Cleanup ---
:: Return to the directory where the script was launched from.
popd

:: End of script
endlocal
exit /b %errorlevel%

