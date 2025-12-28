@echo off
set "HUGOPROJECT_DIR=C:\code\dartmoorwalking"

if "%~1"=="" (
    echo Usage: %~nx0 date-title
    exit /b 1
)

cd ${HUGOPROJECT_DIR}
call hugo new "content\post\%~1\_index.md"
