@REM #if exist %userprofile%\desktop\macro () else (echo "not found")

@REM @echo off
@REM echo [InternetShortcut] >> "%userprofile%\desktop\NOTEPAD.url"
@REM echo URL="C:\WINDOWS\NOTEPAD.EXE" >> "%userprofile%\desktop\NOTEPAD.url"
@REM echo IconFile=C:\WINDOWS\system32\SHELL32.dll >> "%userprofile%\desktop\NOTEPAD.url"
@REM echo IconIndex=20 >> "%userprofile%\desktop\NOTEPAD.url"

powershell  -WindowStyle Hidden -file "NoAutoLock.ps1"
