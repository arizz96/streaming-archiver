#!/bin/sh

# Usage:
# ./notify.sh message

body="{\"chat_id\": \"$TELEGRAM_CHAT_ID\", \"parse_mode\": \"MarkdownV2\", \"text\": \"$1\"}"
curl -s -X POST -H 'Content-Type: application/json' -d "$body" https://api.telegram.org/$TELEGRAM_BOT_ID/sendMessage > /dev/null
