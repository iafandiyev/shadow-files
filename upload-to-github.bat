@echo off
setlocal EnableExtensions

rem Resolve this script's folder WITHOUT a trailing backslash.
rem Robocopy can misparse a quoted path that ends with a backslash.
for %%I in ("%~dp0.") do set "SOURCE_DIR=%%~fI"
set "REPO_URL=https://github.com/iafandiyev/shadow-files.git"
set "WORK_DIR=%TEMP%\shadow-files-github-upload"
set "TARGET_BRANCH="

 echo ==========================================
 echo SHADOW FILES - GitHub Upload
 echo ==========================================
 echo Source: %SOURCE_DIR%
 echo Target: %REPO_URL%
 echo.

if not exist "%SOURCE_DIR%\SHADOWFILES.xcodeproj\project.pbxproj" (
  echo ERROR: SHADOWFILES.xcodeproj was not found.
  echo Extract the complete ZIP and run this BAT from the extracted project folder.
  goto :fail
)

where git >nul 2>&1
if errorlevel 1 (
  echo ERROR: Git is not installed or not in PATH.
  echo Install Git for Windows, then reopen this BAT.
  goto :fail
)

where robocopy >nul 2>&1
if errorlevel 1 (
  echo ERROR: Robocopy was not found. Run this script on Windows.
  goto :fail
)

if exist "%WORK_DIR%" (
  echo Removing previous temporary upload folder...
  rmdir /s /q "%WORK_DIR%"
  if exist "%WORK_DIR%" (
    echo ERROR: Could not remove temporary folder: %WORK_DIR%
    goto :fail
  )
)

echo Cloning the target repository...
git clone "%REPO_URL%" "%WORK_DIR%"
if errorlevel 1 goto :fail

rem Use the branch checked out by clone. Empty repositories may have no branch,
rem so use main as the initial branch in that case.
for /f "delims=" %%B in ('git -C "%WORK_DIR%" branch --show-current 2^>nul') do set "TARGET_BRANCH=%%B"
if not defined TARGET_BRANCH set "TARGET_BRANCH=main"

echo.
echo Copying project files into the cloned repository...
echo Source folder: %SOURCE_DIR%
echo Destination:   %WORK_DIR%
robocopy "%SOURCE_DIR%" "%WORK_DIR%" /E /R:2 /W:2 /XD .git .build build DerivedData
set "ROBOCOPY_EXIT=%ERRORLEVEL%"
if %ROBOCOPY_EXIT% GEQ 8 (
  echo ERROR: Robocopy failed with exit code %ROBOCOPY_EXIT%.
  goto :fail
)

pushd "%WORK_DIR%"
if errorlevel 1 goto :fail

rem Ensure there is a named local branch even when the GitHub repository was empty.
git checkout -B "%TARGET_BRANCH%"
if errorlevel 1 goto :fail_pop

git config user.name "SHADOW FILES Builder"
git config user.email "actions@users.noreply.github.com"

git add -A
if errorlevel 1 goto :fail_pop

git diff --cached --quiet
if not errorlevel 1 (
  echo.
  echo No file changes to upload. GitHub already matches this project folder.
  popd
  pause
  exit /b 0
)

git commit -m "Add SHADOW FILES iOS game project"
if errorlevel 1 goto :fail_pop

echo.
echo Pushing branch %TARGET_BRANCH% to GitHub...
git push -u origin "%TARGET_BRANCH%"
if errorlevel 1 goto :fail_pop

popd
echo.
echo ==========================================
echo UPLOAD COMPLETED SUCCESSFULLY
echo ==========================================
echo Open the repository Actions tab to monitor the iOS IPA build:
echo https://github.com/iafandiyev/shadow-files/actions
echo.
pause
exit /b 0

:fail_pop
popd
:fail
echo.
echo UPLOAD FAILED.
echo Check GitHub authentication, repository permissions, branch protection,
echo internet access, and the error message above.
echo.
pause
exit /b 1
