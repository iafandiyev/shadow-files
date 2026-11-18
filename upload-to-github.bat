@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%I in ("%~dp0.") do set "SOURCE_DIR=%%~fI"
set "REPO_URL=https://github.com/iafandiyev/shadow-files.git"
set "WORK_DIR=%TEMP%\shadow-files-v1-upload"
set "BRANCH=main"

echo ==========================================
echo SHADOW FILES v1.0 - GitHub Upload
echo ==========================================
echo Source: %SOURCE_DIR%
echo Target: %REPO_URL%
echo.

if not exist "%SOURCE_DIR%\SHADOWFILES.xcodeproj\project.pbxproj" (
  echo ERROR: SHADOWFILES.xcodeproj was not found in this folder.
  goto :fail
)

where git >nul 2>&1
if errorlevel 1 (
  echo ERROR: Git for Windows is not installed or not in PATH.
  goto :fail
)
where robocopy >nul 2>&1
if errorlevel 1 (
  echo ERROR: Robocopy is unavailable. This script must run on Windows.
  goto :fail
)

if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"

echo Cloning the current GitHub repository...
git clone "%REPO_URL%" "%WORK_DIR%"
if errorlevel 1 goto :fail

echo.
echo Mirroring the complete v1.0 project into the temporary clone...
echo This removes stale project files from the TEMP clone only; your extracted source folder is untouched.
robocopy "%SOURCE_DIR%" "%WORK_DIR%" /MIR /R:2 /W:2 /XD .git build DerivedData .build /XF *.ipa
set "ROBOCOPY_CODE=%ERRORLEVEL%"
if %ROBOCOPY_CODE% GEQ 8 (
  echo ERROR: Robocopy failed with code %ROBOCOPY_CODE%.
  goto :fail
)

pushd "%WORK_DIR%"
if errorlevel 1 goto :fail

git checkout -B "%BRANCH%"
if errorlevel 1 goto :fail_pop

git config user.name "SHADOW FILES Builder"
git config user.email "actions@users.noreply.github.com"
git add -A
if errorlevel 1 goto :fail_pop

git diff --cached --quiet
if not errorlevel 1 (
  echo No changes to upload. The repository already has these files.
  popd
  pause
  exit /b 0
)

git commit -m "Release SHADOW FILES v1.0"
if errorlevel 1 goto :fail_pop

echo.
echo Pushing v1.0 to GitHub...
git push -u origin "%BRANCH%"
if errorlevel 1 goto :fail_pop

popd
echo.
echo ==========================================
echo UPLOAD COMPLETED
 echo ==========================================
echo Actions: https://github.com/iafandiyev/shadow-files/actions
echo.
pause
exit /b 0

:fail_pop
popd
:fail
echo.
echo UPLOAD FAILED. Check the Git error above and your GitHub authentication.
echo.
pause
exit /b 1
