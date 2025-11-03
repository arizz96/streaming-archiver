#!/bin/sh

# Usage:
# ./programming.sh -p [channel_id|starttime|endtime|name] -d {delay} -D {duration multiplier in %}

# Convert input date (UTC, formatted as YYYY.MM.DD-hh:mm:ss) to crontab format with optional extra minutes
crontab_date() {
  input_date="$1"
  extra_minutes="$2"
  if [ -n "$extra_minutes" ]; then
    input_date=$(date -u -d "@$(( $(date -d $input_date +%s) - $extra_minutes * 60 ))" +"%Y.%m.%d-%H:%M:%S")
  fi

  date -d "$input_date" '+%M %H %d %m *'
}

# Create downloader command with given duration and name
downloader_command() {
  echo "/var/www/html/downloader/downloader.sh -c $1 -t $2 -s 1800 -p 2 -d /var/www/html/videos -n $3"
}

# Calculate the difference in seconds between two dates
seconds_diff() {
  from=$(date -u -d "$1" +%s)
  to=$(date -u -d "$2" +%s)

  echo "$((to - from))"
}

# Round up a number to the nearest half-hour
round_up_to_nearest_halfhour() {
  num="$1"
  multiple=1800
  remainder=$((num % multiple))
  if [ "$remainder" -eq 0 ]; then
    echo "$num"
  else
    rounded_num=$((num + multiple - remainder))
    echo "$rounded_num"
  fi
}

# Replace crontab entries between markers
replace_crontab_entries() {
  new_content="$1"
  channel_id="$2"

  # Create channel specific markers
  begin_marker="# BEGIN ${channel_id} DOWNLOADER AUTOMATIC SECTION"
  end_marker="# END ${channel_id} DOWNLOADER AUTOMATIC SECTION"

  # Check if the marker lines exist in the crontab
  if crontab -l | grep -q -e "$begin_marker" -e "$end_marker"; then
    # Extract the crontab content between the markers
    crontab -l | awk -v content="$new_content" -v begin="$begin_marker" -v end="$end_marker" '
      $0 ~ begin {
        print
        printf "%s\n", content
        in_block = 1
        next
      }
      $0 ~ end {
        print
        in_block = 0
        next
      }
      !in_block { print }
    ' | crontab -
  else
    # If markers don't exist, append new section
    (crontab -l 2>/dev/null; echo "$begin_marker"; echo -e "$new_content"; echo; echo "$end_marker") | crontab -
  fi
}

read_crontab_entries() {
  channel_id="$1"

  # Create channel specific markers
  begin_marker="# BEGIN ${channel_id} DOWNLOADER AUTOMATIC SECTION"
  end_marker="# END ${channel_id} DOWNLOADER AUTOMATIC SECTION"

  # Check if the marker lines exist in the crontab
  if crontab -l | grep -q -e "$begin_marker" -e "$end_marker"; then
    # Extract the crontab content between the markers, excluding the header and footer
    crontab -l | awk -v begin="$begin_marker" -v end="$end_marker" '
      $0 ~ begin { start=1; next }
      $0 ~ end { start=0; exit }
      start { print }
    '
  else
    echo "Error: The specified section markers for channel ${channel_id} are not found in the crontab."
    return 1
  fi
}

# Function to convert crontab details into a human-readable format
convert_cron_to_human() {
  crontab_entry="$1"

  # Extract crontab fields
  minute=$(echo "$crontab_entry" | awk '{print $1}')
  hour=$(echo "$crontab_entry" | awk '{print $2}')
  day=$(echo "$crontab_entry" | awk '{print $3}')
  month=$(echo "$crontab_entry" | awk '{print $4}')
  weekday=$(echo "$crontab_entry" | awk '{print $5}')

  # Extract the command part
  command=$(echo "$crontab_entry" | cut -d' ' -f6-)

  # Break down the command and initialize variables
  command_parts=$(echo "$command" | tr ' ' '\n')
  found_duration=0
  found_name=0

  # Loop through command parts to find -t and -n flags
  for part in $command_parts; do
    if [ "$found_duration" -eq 1 ]; then
      duration="$part"
      found_duration=0 # Reset flag after capturing value
    elif [ "$found_name" -eq 1 ]; then
      name="$part"
      found_name=0 # Reset flag after capturing value
    elif [ "$part" = "-t" ]; then
      found_duration=1
    elif [ "$part" = "-n" ]; then
      found_name=1
    fi
  done

  # Validate duration as a numeric value
  if [ -z "$duration" ] || ! echo "$duration" | grep -qE '^[0-9]+$'; then
    echo "Error: duration is not a valid number"
    return 1
  fi

  # Convert duration to hours and minutes
  duration_hours=$(expr "$duration" / 3600)
  duration_minutes=$(expr '(' "$duration" % 3600 ')' / 60)

  # Construct the scheduled time
  scheduled_time=$(date -d "2024-$month-$day $hour:$minute:00" +"%Y-%m-%d %H:%M:%S")

  # Output the formatted message
  echo "*$name* scheduled for *$scheduled_time* for $duration_hours hour(s) and $duration_minutes minute(s)"
}

notify_telegram() {
  # List of crontab entries (assumed to be in UTC)
  crontab_content="$1"
  parsed_content=""

  # Loop through each crontab entry
  IFS=$'\n'  # Set Internal Field Separator to newline
  for crontab_entry in $crontab_content; do
    parsed_content="$parsed_content\n$(convert_cron_to_human $crontab_entry)"
  done

  message="The crontab content changed to:\n\`\`\`$parsed_content\`\`\`"
  /var/www/html/downloader/notify.sh $message
}

# Get input options
while getopts ":p:d:D:c:" opt; do
  case $opt in
    p)
      programming="$OPTARG"
      ;;
    d)
      delay="$OPTARG"
      ;;
    D)
      duration="$OPTARG"
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

# Set default duration if not provided
if [ -z "$duration" ]; then
  duration=100
fi

# Split the programming variable into an array
IFS=' ' # Set field separator to space
programming_array=$(echo "$programming")

# Initialize crontab content
crontab=""

# Loop through the entries and construct crontab content
for entry in $programming_array; do
  IFS='|' read -r starttime endtime name <<EOL
$entry
EOL

  duration_seconds=$(seconds_diff "$starttime" "$endtime")
  duration_seconds=$((duration_seconds + (delay * 60))) # Add delay
  duration_seconds=$((duration_seconds * duration / 100)) # Apply duration multiplier
  duration_seconds=$(round_up_to_nearest_halfhour "$duration_seconds") # Round up to nearest half-hour

  crontab_entry=$(crontab_date "$starttime" "$delay")
  crontab_entry="${crontab_entry} $(downloader_command "$channel" "$duration_seconds" "$name")"

  if [ -z "$crontab" ]; then
    crontab="$crontab_entry"
  else
    crontab=$(echo -e "$crontab\n$crontab_entry")
  fi
done

old_crontab=$(read_crontab_entries)

# Replace crontab entries with the new content
replace_crontab_entries "$crontab" "$channel"
new_crontab=$(read_crontab_entries "$channel")

# Notify if a new crontab has been installed
if [[ "$old_crontab" != "$new_crontab" ]]; then
  echo "$new_crontab"
  notify_telegram "$new_crontab"
fi
