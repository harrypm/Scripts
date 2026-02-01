# PowerShell version of align script
# Usage: align.ps1 input_audio_file.flac|.wav metadata_file.json

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Arg1,
    [Parameter(Position=1, Mandatory=$true)]
    [string]$Arg2
)

# Define paths for dependencies
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AAA_EXE = Join-Path $ScriptDir "VhsDecodeAutoAudioAlign.exe"

function Print-Usage {
    Write-Host "Usage: align.ps1 <input_audio_file.flac|.wav> <metadata_file.json>"
    exit 1
}

# Auto-detect and assign audio_file & metadata_file regardless of order
$Extension1 = [System.IO.Path]::GetExtension($Arg1).ToLower()
$Extension2 = [System.IO.Path]::GetExtension($Arg2).ToLower()

if ($Extension1 -eq ".json") {
    $MetadataFile = $Arg1
    $AudioFile = $Arg2
} elseif ($Extension1 -in @(".flac", ".wav")) {
    $AudioFile = $Arg1
    $MetadataFile = $Arg2
} elseif ($Extension2 -eq ".json") {
    $MetadataFile = $Arg2
    $AudioFile = $Arg1
} elseif ($Extension2 -in @(".flac", ".wav")) {
    $AudioFile = $Arg2
    $MetadataFile = $Arg1
} else {
    Write-Host "Error: Could not identify an audio file (.flac/.wav) and a JSON file among arguments."
    Print-Usage
}

# Ensure the input files exist
if (-not (Test-Path $AudioFile)) {
    Write-Host "Error: Audio file '$AudioFile' not found."
    exit 1
}

if (-not (Test-Path $MetadataFile)) {
    Write-Host "Error: Metadata file '$MetadataFile' not found."
    exit 1
}

# Confirm extensions again
$AudioExt = [System.IO.Path]::GetExtension($AudioFile).ToLower()
if ($AudioExt -notin @(".flac", ".wav")) {
    Write-Host "Error: '$AudioFile' is not a .flac or .wav file."
    exit 1
}

# Check for dependencies
$RequiredCommands = @("ffmpeg", "ffprobe")
foreach ($Cmd in $RequiredCommands) {
    try {
        $null = Get-Command $Cmd -ErrorAction Stop
    } catch {
        Write-Host "Error: $Cmd is required but not found in PATH."
        exit 1
    }
}

# Check for VhsDecodeAutoAudioAlign.exe
if (Test-Path $AAA_EXE) {
    $AAA_PATH = $AAA_EXE
} else {
    Write-Host "Error: VhsDecodeAutoAudioAlign.exe not found in script directory:"
    Write-Host "  - $AAA_EXE"
    exit 1
}

# Determine the sample rate using ffprobe
$SampleRateOutput = & ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$AudioFile" 2>$null
$SampleRate = $SampleRateOutput.Trim()

Write-Host "Detected sample rate: $SampleRate Hz"

# Prepare output path
$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($AudioFile)
$OutputFile = "${BaseName}_aligned.flac"

# Handle different sample rates dynamically
switch ($SampleRate) {
    "48000" {
        Write-Host "Source is 48000 Hz. Using 48000 Hz parameters."
        
        & ffmpeg -i "$AudioFile" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 -ar 48000 - | & "$AAA_PATH" stream-align --sample-size-bytes 6 --stream-sample-rate-hz 48000 --json "$MetadataFile" --rf-video-sample-rate-hz 40000000 | & ffmpeg -f s24le -ar 48000 -ac 2 -i - -sample_fmt s32 "$OutputFile"
    }
    
    "78125" {
        Write-Host "Source is 78125 Hz. Using 78125 Hz parameters."
        
        & ffmpeg -i "$AudioFile" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 -ar 78125 - | & "$AAA_PATH" stream-align --sample-size-bytes 6 --stream-sample-rate-hz 78125 --json "$MetadataFile" --rf-video-sample-rate-hz 40000000 | & ffmpeg -f s24le -ar 78125 -ac 2 -i - -af aresample=48000 -sample_fmt s32 "$OutputFile"
    }
    
    "46875" {
        Write-Host "Source is 46875 Hz. Using 46875 Hz for alignment then resampling to 48000 Hz."
        
        & ffmpeg -i "$AudioFile" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 - | & "$AAA_PATH" stream-align --sample-size-bytes 6 --stream-sample-rate-hz 46875 --json "$MetadataFile" --rf-video-sample-rate-hz 40000000 | & ffmpeg -f s24le -ar 46875 -ac 2 -i - -af aresample=48000 -sample_fmt s32 "$OutputFile"
    }
    
    default {
        Write-Host "Source is $SampleRate Hz. Using detected sample rate for alignment then resampling to 48000 Hz."
        
        & ffmpeg -i "$AudioFile" -filter_complex "channelmap=map=FL-FL|FR-FR" -f s24le -ac 2 -ar $SampleRate - | & "$AAA_PATH" stream-align --sample-size-bytes 6 --stream-sample-rate-hz $SampleRate --json "$MetadataFile" --rf-video-sample-rate-hz 40000000 | & ffmpeg -f s24le -ar $SampleRate -ac 2 -i - -af aresample=48000 -sample_fmt s32 "$OutputFile"
    }
}

Write-Host "Output written to '$OutputFile'"