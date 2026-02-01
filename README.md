# RF Scripts


Scripts repository for use with the [decode projects](https://github.com/oyvindln/vhs-decode/wiki).


# Clockgen Scripts


- Direct

Direct offers direct output from both cards at 40msps 8-bit ideal for lower end systems that can't resample with SoX or resampling is prefered to be done manually later for HiFi FM RF audio.

- Resampled

This script was the orginal script, now its a go to for higher end systems that can cope with real-time SoX resampling or 4:1 downsampling for HiFi FM RF. 

- SoX Benchmark

This script simply benchmarks your CPUs proformace abbility with SoX usefull to find out if somthing is very wrong or yours systems abbilitys.


# Auto Audio Align

- align

This script is ment for easy global auto audio alignment of 46875 Hz, 78125 Hz & 48000 Hz files via same clock Baseband captures from the CX Card Clockgen Mod workflow, the MISRC V2.5 workflow and HiFi-Decode's stock 48khz output.

This will take .JSON decode data for frame offset refrence and or .wav/.flac audio files either first or last in order, and will assume Video RF rate based off a same name local file in the directory if rates are stated inside of the file i.g `my-tape-40msps.flac` for example.


# FFV1

This script is ment for processing legacy uncompressed V210 mov or avi captures, this was used for BMD Media Express captures transcodes before moving to Vrecord, FFV1 + AVC proxy direct capture for inital runs.


# Fix Decode JSON

This script is ment for fixing JSON files with incorrect or wacky bSNR values or "black signal to noise ratio" when decode genrates an out of real world number drastically above the media's actual bSNR vlaue, this is very useful for when the JSON is being read inside of ld-analyse to view in graphing form and would be redering off screen outherwise.


# Proxy

- proxy

This script is a master proxy genaration script, AVC stock config is Youtube supported and Odysee ready, also has OPUS/HEVC, uses web-ready MP4.
