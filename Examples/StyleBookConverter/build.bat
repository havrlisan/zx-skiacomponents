@echo off
REM Build the StyleBookConverter console app.

IF NOT DEFINED BDS (
  CALL "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
)

pushd "%~dp0"

set ZX_SRC=%~dp0..\..\source

dcc64 -B -Q ^
  -NSSystem;System.Win;Winapi;FMX;Vcl;Data ^
  -U"%BDS%\source\fmx;%BDS%\lib\win64\release;%ZX_SRC%" ^
  -R"%BDS%\source\fmx;%BDS%\lib\win64\release" ^
  StyleBookConverter.dpr

set RC=%ERRORLEVEL%
popd
exit /b %RC%
