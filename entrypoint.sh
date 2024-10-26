#!/bin/sh

# Ensure videos folder has right permission.
chown -R apache:apache videos

# Start cron daemon.
crond -b -L /var/log/crond.log -l 5

# Start application.
httpd -D FOREGROUND
