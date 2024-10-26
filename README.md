# Instructions for NanoPi NEO Plus 2

## Automount sdcard

Follow [this guide](https://askubuntu.com/a/165462):
```
# Create folder
mkdir /sdcard
# Find device name
lsblk -o NAME,FSTYPE,UUID
# Mount it
mount {device} /sdcard
# Add entry to /etc/fstab
{device} /sdcard vfat defaults 0 0
```

# Install Docker
Follow official [guide](https://docs.docker.com/engine/install/ubuntu/).

# Clone the repository
`git clone ...`

# Create a `.htpasswd` file
Adding a `.htpasswd` file in the root allows a custom Basic Auth to your web page

# Build the image
`docker build . -t streaming-archiver`

# Run Docker image
`docker run -d --restart always --name streaming_archiver_runner -p 80:80 -v /sdcard/downloader_videos:/var/www/html/videos -v ./.htpasswd:/etc/apache2/.htpasswd --env TELEGRAM_BOT_ID=xxx --env TELEGRAM_CHAT_ID=xxx streaming-archiver`

# To enter Docker container
`docker exec -it streaming_archiver_runner sh`
`docker exec --user apache -it streaming_archiver_runner sh`
