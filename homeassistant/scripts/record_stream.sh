#!/bin/sh
# Usage: record_stream.sh <url|""> <seconds> <name> <channel>
# Starts ffmpeg detached and returns immediately (Home Assistant's shell_command
# is killed after 60s). With an empty url, runs the channel's URL script.

url="$1"
secs="$2"
name="$3"
channel="${4:-channel1}"

DEST="${RECORD_DEST:-/media/recordings}"
SCRIPT_DIR="${CHANNEL_SCRIPT_DIR:-/config/downloader}"
PROGRAM="${STREAM_PROGRAM:-2}"   # -map p:N, same as downloader.sh -p

mkdir -p "$DEST"

if [ -z "$url" ]; then
  url=$(sh "$SCRIPT_DIR/${channel}_download_url.sh")
fi
if [ -z "$url" ]; then
  echo "$(date) no stream url for $channel" >> "$DEST/record.log"
  exit 1
fi

nohup ffmpeg -nostdin -loglevel warning -i "$url" \
  -f segment -segment_time 1800 \
  -reset_timestamps 1 \
  -map "p:$PROGRAM" -map -0:s \
  -t "$secs" \
  -c copy "$DEST/${name}_$(date '+%Y%m%d%H%M%S')_%d.mp4" \
  >> "$DEST/record.log" 2>&1 < /dev/null &
