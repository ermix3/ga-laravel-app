FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    bash \
    curl \
    git \
    unzip \
    libpng \
    libpng-dev \
    libjpeg-turbo \
    libjpeg-turbo-dev \
    freetype \
    freetype-dev \
    libzip-dev \
    zip \
    icu-dev \
    oniguruma-dev \
    zlib-dev \
    libxml2-dev \
    shadow \
    supervisor

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql zip mbstring intl gd bcmath

# Set working directory
WORKDIR /var/www/html

# Copy Laravel project
COPY . .

# Copy custom nginx config
COPY nginx.backend.conf /etc/nginx/nginx.conf

# Give permissions
RUN usermod -u 1000 www-data \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage

# Expose port for Nginx
EXPOSE 8000

# Start both PHP-FPM and Nginx
CMD [ "sh", "-c", "php-fpm & nginx -g 'daemon off;'" ]
