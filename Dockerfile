# Start with Alpine Linux as the base image
FROM alpine:3.19

# Install Apache2 and PHP
RUN apk add --no-cache \
    apache2 \
    apache2-ctl \
    apache2-utils \
    php81-apache2 \
    php81 \
    php81-session \
    php81-openssl \
    php81-mbstring \
    php81-json \
    curl \
    ffmpeg \
    jq \
    yq \
    busybox-suid

WORKDIR /var/www/html

RUN echo "LoadModule php_module /usr/lib/apache2/modules/libphp81.so" >> /etc/apache2/httpd.conf
COPY video-player.conf /etc/apache2/conf.d/video-player.conf

# Create videos folder
RUN mkdir videos

# Init crontab
COPY crontab /etc/crontab
RUN crontab -u apache /etc/crontab

# Copy all the files
COPY downloader downloader
COPY html/* .
COPY entrypoint.sh entrypoint.sh

# Fix permissions
RUN chown -R apache:apache . && \
    chmod +x downloader/* && \
    chmod +x entrypoint.sh

EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]
