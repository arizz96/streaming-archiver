#!/bin/sh

# Usage:
# ./downloader.sh -c 0 -t {duration_in_seconds} -s #{segment_time_in_seconds} -p 2 -d {output_folder} -n #{output_prefix}

# operation, name
notify_telegram() {
  operation="$1"
  name="$2"

  IFS=$'\n'  # Set Internal Field Separator to newline
  message="*$operation* streaming of: \`\`\`$name\`\`\`"
  /var/www/html/downloader/notify.sh $message
}

# url, segment_time, program, time, destination, name
# The -map -0:s command skips subtitle track.
download_stream() {
  ffmpeg -i $1 \
    -f segment -segment_time $2 \
    -reset_timestamps 1 \
    -map p:$3 -map -0:s \
    -t $4 \
    -c copy $5/$6_$(date '+%Y%m%d%H%M%S')_%d.mp4
}

# Get input options
while getopts ":c:d:s:p:t:n:" opt; do
  case $opt in
    c)
      channel_id="$OPTARG" ;;
    d)
      destination="$OPTARG" ;;
    s)
      segment_time="$OPTARG" ;;
    p)
      program="$OPTARG" ;;
    t)
      time="$OPTARG" ;;
    n)
      name="$OPTARG" ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Add your stream URL here
# ...
url=

notify_telegram "start" $name

download_stream \
  $url \
  $segment_time \
  $program \
  $time \
  $destination \
  $name

notify_telegram "end" $name
