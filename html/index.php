<!DOCTYPE html>
<html>
    <head>
        <title>Video Player for Files</title>
        <style>
            body {
                font-family: 'Courier New', Courier, monospace;
            }
            .video-container {
                float: left;
                margin-right: 10px;
            }
        </style>
    </head>
    <body>
        <h1>Crontab configuration:</h1>
        <?php
            function getCrontabSchedule() {
                // Get all sections using grep to match any channel id
                $output = `crontab -l | grep -A 1000 "# BEGIN.*DOWNLOADER AUTOMATIC SECTION" | grep -B 1000 "# END.*DOWNLOADER AUTOMATIC SECTION"`;
                $lines = explode("\n", $output);
                $schedule = array();

                $collecting = false;
                foreach ($lines as $line) {
                    if (strpos($line, "# BEGIN") !== false) {
                        $collecting = true;
                        continue;
                    }
                    if (strpos($line, "# END") !== false) {
                        $collecting = false;
                        continue;
                    }
                    if ($collecting && trim($line) !== '') {
                        $schedule[] = $line;
                    }
                }

                return $schedule;
            }

            function getNextOccurrence($cronExpression) {
              // Parse the cron expression
              $cronParts = explode(' ', $cronExpression);

              // Get the current date and time
              $currentDateTime = new DateTime();

              // Calculate the next minute, hour, day, month, and year based on the cron expression
              $nextMinute = $cronParts[0];
              $nextHour = $cronParts[1];
              $nextDayOfMonth = $cronParts[2];
              $nextMonth = $cronParts[3];
              $nextYear = $currentDateTime->format('Y');

              // Create a DateTime object for the next occurrence
              $nextOccurrence = new DateTime("$nextYear-$nextMonth-$nextDayOfMonth $nextHour:$nextMinute:00");

              // Set IT time zone
              $nextOccurrence->setTimezone(new DateTimeZone('Europe/Rome'));

              return $nextOccurrence->format('Y-m-d H:i:s (e)');
          }

          function findElementIndex($array, $string) {
              foreach ($array as $index => $element) {
                  if ($element === $string) {
                      return $index;
                  }
              }
              return -1; // Return -1 if no match is found
          }

          foreach (getCrontabSchedule() as $cronEntry) {
              $explodedCronEntry = explode(' ', $cronEntry);
              $cronExpression = join(" ", array_slice($explodedCronEntry, 0, 5));
              $downloadDuration = $explodedCronEntry[findElementIndex($explodedCronEntry, "-t") + 1];
              $downloadName = $explodedCronEntry[findElementIndex($explodedCronEntry, "-n") + 1];
              echo "<strong>" . $downloadName . "</strong> scheduled for <strong>" . getNextOccurrence($cronExpression) . "</strong> for " . ($downloadDuration / 60 / 60) . " hours<br/>";
          }
        ?>
        <h1>Files in the Directory:</h1>
        <?php
            $dir = "videos/"; // Specify the directory path here
            $files = array_diff(scandir($dir), array('..', '.')); // Fetch all files from the directory

            $groupedFiles = array();

            // Group files based on the common part of filenames
            foreach ($files as $file) {
                // Check if the file is a video file
                if (pathinfo($file, PATHINFO_EXTENSION) == "mp4" || pathinfo($file, PATHINFO_EXTENSION) == "m3u8") {
                    $filename = pathinfo($file, PATHINFO_FILENAME);

                    // Extract the timestamp part
                    $filenameParts = explode('_', $filename);
                    $timestamp = $filenameParts[count($filenameParts) - 2]; // Assuming timestamp is the second-to-last part
                    // Extract the name part
                    $name = join(" ", array_slice($filenameParts, 0, count($filenameParts) - 2));

                    // Convert the timestamp part to a human-readable date format
                    $date = DateTime::createFromFormat('YmdHis', $timestamp);
                    $humanReadableDate = $date->format('F j, Y, H:i');
                    // Group files
                    $groupedFiles[$name . " - " . $humanReadableDate][] = $file;
                }
            }

            // Display grouped files
            foreach ($groupedFiles as $groupName => $files) {
                echo '<h2>' . $groupName . '</h2>';
                foreach ($files as $file) {
                    $filedir = $dir . $file;
                    echo '<div class="video-container">';
                    $fileIndex = substr($file, strrpos($file, '_'));
                    echo '<h3>' . $fileIndex . '</h3>';
                    echo '<video width="320" height="240" controls preload="none">
                            <source src="' . $filedir . '" type="' . (pathinfo($filedir, PATHINFO_EXTENSION) == "mp4" ? 'video/mp4' : 'application/x-mpegURL') . '">
                            Your browser does not support the video tag.
                          </video>';
                    echo '</div>';
                }
                echo '<div style="clear:both;"></div>'; // Clear floats after each group of videos
            }
        ?>
    </body>
</html>
