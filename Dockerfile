# Multi-stage build for production
FROM composer:2 AS builder

WORKDIR /app
COPY . .
RUN composer install --no-dev --optimize-autoloader

FROM php:8.2-fpm-alpine

WORKDIR /var/www/html
COPY --from=builder /app .

# Install dependencies
RUN apk add --no-cache \
    libzip-dev \
    zip \
    && docker-php-ext-install pdo pdo_mysql zip

# Permissions
RUN chown -R www-data:www-data /var/www/html/storage
RUN chmod -R 775 /var/www/html/storage

# Environment variables will be passed at runtime
CMD ["php-fpm"]
