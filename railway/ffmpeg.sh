#!/bin/sh
# Shoutrrr calls ffmpeg to turn GIFs into MP4 for Bluesky. On Railway ffmpeg
# would start threads for every host CPU (32+); cap them to the service's CPUs.
# -filter_threads goes first (global option), -threads right before the output file.
T="${SHOUTRRR_FFMPEG_THREADS:-2}"
if [ "$#" -lt 2 ]; then
    exec /usr/bin/ffmpeg "$@"
fi
n=$#
i=0
for a in "$@"; do
    i=$((i + 1))
    if [ "$i" -eq "$n" ]; then
        set -- "$@" -threads "$T" "$a"
    else
        set -- "$@" "$a"
    fi
    shift
done
exec /usr/bin/ffmpeg -filter_threads "$T" "$@"
