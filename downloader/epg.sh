#!/bin/bash

# Log a message with a timestamp
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Fetch JSON data based on the given day and content URL
fetch_schedule_raw_data() {
    day="$1"
    channel_id="$2"
    config_file="${CONFIG_FILE:-./channels.yml}"
    schedule_script=$(cat $config_file | yq -r ".channels[] | select(.id == \"$channel_id\") | .schedule_json_script")

    if [ -f "./$schedule_script" ]; then
        sh "./$schedule_script" "$day"
    else
        echo "Error: Schedule script not found"
        return 1
    fi
}

# Process JSON data and extract required information
process_schedule() {
  json_data="$1"
  channel_id="$2"
  results=""

  # Read and process each line of JSON data
  while IFS= read -r line; do
    starttime=$(echo "$line" | jq -r '.starttime' | sed 's/-/./g' | sed 's/T/-/g' | sed 's/Z//')
    endtime=$(echo "$line" | jq -r '.endtime' | sed 's/-/./g' | sed 's/T/-/g' | sed 's/Z//')

    contentTitle=$(echo "$line" | jq -r '.contentTitle' | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    contentTitle=${contentTitle//[^a-zA-Z0-9\_]/}

    episodeNumber=$(echo "$line" | jq -r '.episodeNumber')
    seasonNumber=$(echo "$line" | jq -r '.seasonNumber')

    # Concatenate information
    entry="${channel_id}|$starttime|$endtime|${contentTitle}_${seasonNumber}_${episodeNumber}"

    results="${results}${entry} "
  done << EOF
$json_data
EOF

  # Return results as output
  echo -e "$results"
}

# Parsing command-line options
while getopts ":d:c:" opt; do
  case $opt in
    d)
      dows="$OPTARG"
      ;;
    c)
      channel="$OPTARG"
      ;;
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

# Prepare array of days of the week
IFS=','
dow_array=$(echo "$dows" | tr -d ' ')

scheduler_entries=""

# Loop over days of the week and fetch/process JSON data
for dow in $(echo "$dow_array"); do
  log "Running for: $dow / $channel"

  schedule_raw_data=$(fetch_schedule_raw_data "$dow" "$channel")
  log "Retrieved $schedule_raw_data"

  if [ -n "$schedule_raw_data" ]; then
    processed_results=$(process_schedule "$schedule_raw_data" "$channel")
    log "Processed $processed_results"

    scheduler_entries="${scheduler_entries}${processed_results} "
  else
    log "Skipping since data is empty"
  fi
done

log "Calling programming script with: $scheduler_entries"
/var/www/html/downloader/programming.sh -p "$scheduler_entries" -d 10 -D 150
