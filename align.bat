@echo off
setlocal enabledelayedexpansion

REM Windows batch version of align script
REM Usage: align.bat input_audio_file.flac|.wav metadata_file.json

REM Define paths for dependencies
set "AAA_EXE=%~dp0VhsDecodeAutoAudioAlign.exe"

REM Check if exactly two arguments are provided
if "%~2"=="" goto :usage
if not "%~3"=="" goto :usage

set "arg1=%~1"
set "arg2=%~2"

REM Auto-detect and assign audio_file & metadata_file regardless of order
set "ext1=%~x1"
set "ext2=%~x2"

if /i "%ext1%"==".json" (
    set "metadata_file=%arg1%"
    set "audio_file=%arg2%"
) else if /i "%ext1%"==".flac" (
    set "audio_file=%arg1%"
    set "metadata_file=%arg2%"
) else if /i "%ext1%"==".wav" (
    set "audio_file=%arg1%"
    set "metadata_file=%arg2%"
) else if /i "%ext2%"==".json" (
    set "metadata_file=%arg2%"
    set "audio_file=%arg1%"
) else if /i "%ext2%"==".flac" (
    set "audio_file=%arg2%"
    set "metadata_file=%arg1%"
) else if /i "%ext2%"==".wav" (
    set "audio_file=%arg2%"
    set "metadata_file=%arg1%"
) else (
    echo Error: Could not identify an audio file (.flac/.wav) and a JSON file among arguments.
    goto :usage
)

REM Ensure the input files exist
if not exist "%audio_file%" (
    echo Error: Audio file '%audio_file%' not found.
    exit /b 1
)

if not exist "%metadata_file%" (
    echo Error: Metadata file '%metadata_file%' not found.
    exit /b 1
)

REM Check for dependencies
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: ffmpeg is required but not found in PATH.
    exit /b 1
)

where ffprobe >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: ffprobe is required but not found in PATH.
    exit /b 1
)

REM Check for VhsDecodeAutoAudioAlign.exe
if exist "%AAA_EXE%" (
    set "AAA_PATH=%AAA_EXE%"
) else (
    echo Error: VhsDecodeAutoAudioAlign.exe not found in script directory:
    echo   - %AAA_EXE%
    exit /b 1
)

REM Determine the sample rate using ffprobe
for /f "delims=" %%i in ('ffprobe -v error -select_streams a:0 -show_entries stream^=sample_rate -of default^=noprint_wrappers^=1:nokey^=1 "%audio_file%" 2^>nul') do set "samplerate=%%i"

echo Detected sample rate: %samplerate% Hz

REM Prepare output path
for %%f in ("%audio_file%") do set "basename=%%~nf"
set "output=%basename%_aligned.flac"

REM Handle different sample rates dynamically
if "%samplerate%"=="48000" (
    echo Source is 48000 Hz. Using 48000 Hz parameters.
    ffmpeg -i "%audio_file%" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 -ar 48000 - | "%AAA_PATH%" stream-align --sample-size-bytes 6 --stream-sample-rate-hz 48000 --json "%metadata_file%" --rf-video-sample-rate-hz 40000000 | ffmpeg -f s24le -ar 48000 -ac 2 -i - -sample_fmt s32 "%output%"
) else if "%samplerate%"=="78125" (
    echo Source is 78125 Hz. Using 78125 Hz parameters.
    ffmpeg -i "%audio_file%" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 -ar 78125 - | "%AAA_PATH%" stream-align --sample-size-bytes 6 --stream-sample-rate-hz 78125 --json "%metadata_file%" --rf-video-sample-rate-hz 40000000 | ffmpeg -f s24le -ar 78125 -ac 2 -i - -af aresample=48000 -sample_fmt s32 "%output%"
) else if "%samplerate%"=="46875" (
    echo Source is 46875 Hz. Using 46875 Hz for alignment then resampling to 48000 Hz.
    ffmpeg -i "%audio_file%" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 - | "%AAA_PATH%" stream-align --sample-size-bytes 6 --stream-sample-rate-hz 46875 --json "%metadata_file%" --rf-video-sample-rate-hz 40000000 | ffmpeg -f s24le -ar 46875 -ac 2 -i - -af aresample=48000 -sample_fmt s32 "%output%"
) else (
    echo Source is %samplerate% Hz. Using detected sample rate for alignment then resampling to 48000 Hz.
    ffmpeg -i "%audio_file%" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 -ar %samplerate% - | "%AAA_PATH%" stream-align --sample-size-bytes 6 --stream-sample-rate-hz %samplerate% --json "%metadata_file%" --rf-video-sample-rate-hz 40000000 | ffmpeg -f s24le -ar %samplerate% -ac 2 -i - -af aresample=48000 -sample_fmt s32 "%output%"
)

echo Output written to '%output%'
goto :eof

:usage
echo Usage: %~n0 ^<input_audio_file.flac^|.wav^> ^<metadata_file.json^>
exit /b 1