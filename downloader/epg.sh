#!/bin/sh

# Log a message with a timestamp
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Fetch JSON data based on the given day and content URL
fetch_schedule_raw_data() {
  # Add you logic for schedule retrieving here
  # ...
  # Example: curl -s https://... | jq -r ...
}

# Process JSON data and extract required information
process_schedule() {
  # Add you logic for schedule parsing here
  # ...
  # The single entry format (each `results` line) is:
  # "$starttime|$endtime|${name}"

  results=""

  # Return results as output
  echo -e "$results"
}

# Parsing command-line options
while getopts ":d:u:" opt; do
  case $opt in
    d)
      dows="$OPTARG"
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
  log "Running for: $dow"

  schedule_raw_data=$(fetch_schedule_raw_data "$dow")
  log "Retrieved $schedule_raw_data"

  if [ -n "$schedule_raw_data" ]; then
    processed_results=$(process_schedule "$schedule_raw_data")
    log "Processed $processed_results"

    scheduler_entries="${scheduler_entries}${processed_results} "
  else
    log "Skipping since data is empty"
  fi

done

log "Calling programming script with: $scheduler_entries"
/var/www/html/downloader/programming.sh -p "$scheduler_entries" -d 10 -D 150
