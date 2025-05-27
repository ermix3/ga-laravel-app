# Stage 1: Build - install composer dependencies
FROM composer:2 AS builder

WORKDIR /app

# Copy composer files separately for caching
COPY composer.json composer.lock ./

# Install PHP dependencies (no dev)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts --prefer-dist

# Copy the rest of the app files
COPY . .

# Run any additional build steps here if needed (e.g. npm run production for assets)

# Stage 2: Runtime - PHP + Nginx
FROM php:8.2-fpm-alpine

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    nginx \
    bash \
    libpng libpng-dev \
    libjpeg-turbo libjpeg-turbo-dev \
    freetype freetype-dev \
    libzip-dev zip \
    icu-dev oniguruma-dev zlib-dev libxml2-dev shadow supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql zip mbstring intl gd bcmath opcache

# Configure PHP for file uploads
RUN { \
    echo 'file_uploads = On'; \
    echo 'upload_max_filesize = 20M'; \
    echo 'post_max_size = 21M'; \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
} > /usr/local/etc/php/conf.d/uploads.ini

# Create www-data user with uid 1000 (for permission consistency)
RUN usermod -u 1000 www-data

WORKDIR /var/www/html

# Copy the app code from builder, including vendor folder
COPY --from=builder /app /var/www/html

# Clear any cached Laravel config from build context
RUN php artisan config:clear && php artisan route:clear

# Copy nginx config
COPY nginx.backend.conf /etc/nginx/nginx.conf

# Permissions for storage and bootstrap cache
# Ensure php-fpm uses a socket
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache \
    && sed -i 's|^listen = .*|listen = 9000|' /usr/local/etc/php-fpm.d/www.conf

# Expose port 8000
EXPOSE 8000

# Start PHP-FPM and Nginx together
CMD ["sh", "-c", "php-fpm & nginx -g 'daemon off;'"]
