#!/bin/sh
# Usage:
#   record_stream.sh start <key> <url> <name>
#   record_stream.sh stop  <key>
# `start` runs ffmpeg detached (Home Assistant kills shell_command after 60s) and
# stores its pid under <key>; `stop` ends it cleanly so the last segment is finalised.

cmd="$1"
key="$2"

DEST="${RECORD_DEST:-/media/recordings}"
RUN="${RECORD_RUN:-/config/.recording_pids}"
PROGRAM="${STREAM_PROGRAM:-2}"        # -map p:N, as downloader.sh -p
MAX_SECS="${RECORD_MAX_SECS:-21600}"  # safety net if the stop never fires

mkdir -p "$DEST" "$RUN"

case "$cmd" in
  start)
    url="$3"
    name="$4"
    nohup ffmpeg -nostdin -loglevel warning -i "$url" \
      -f segment -segment_time 1800 \
      -reset_timestamps 1 \
      -map "p:$PROGRAM" -map -0:s \
      -t "$MAX_SECS" \
      -c copy "$DEST/${name}_$(date '+%Y%m%d%H%M%S')_%d.mp4" \
      >> "$DEST/record.log" 2>&1 < /dev/null &
    echo $! > "$RUN/$key.pid"
    ;;
  stop)
    pid=$(cat "$RUN/$key.pid" 2>/dev/null) || exit 0
    if grep -q ffmpeg "/proc/$pid/cmdline" 2>/dev/null; then
      kill -INT "$pid"
    fi
    rm -f "$RUN/$key.pid"
    ;;
  *)
    echo "usage: $0 start|stop" >&2
    exit 1
    ;;
esac
