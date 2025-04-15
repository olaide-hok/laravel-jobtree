# Stage 1: Build assets
FROM node:22 as node-build
WORKDIR /app
COPY . .
RUN npm install && npm run build

# Stage 2: PHP build and Laravel setup
FROM php:8.2-fpm
WORKDIR /app

# Install PHP dependencies
# RUN apt-get update && apt-get install -y \
#     git unzip curl libzip-dev libpq-dev libonig-dev libxml2-dev \
#     && docker-php-ext-install pdo pdo_mysql zip bcmath opcache

RUN apt-get update && apt-get install -y \
    nginx \
    git \
    unzip \
    curl \
    zip \
    libzip-dev \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    supervisor \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath opcache

# Copy codebase from node build
COPY --from=node-build /app /app
COPY --from=node-build /app/public /app/public

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --optimize-autoloader --no-dev

# Laravel: Cache config, routes, views
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan storage:link

# Stage 3: Production (Nginx)
FROM nginx:1.25-alpine
WORKDIR /var/www/html

# Copy app from PHP build stage
# COPY --from=php-build /app /var/www/html

# Add nginx config
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf

# Copy Supervisor config
COPY ./conf/supervisord.conf /etc/supervisord.conf

# PHP-FPM setup
# COPY --from=php-build /usr/local/etc/php-fpm.d/ /usr/local/etc/php-fpm.d/
# COPY --from=php-build /usr/local/bin/php /usr/local/bin/php
# COPY --from=php-build /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm

# Image config
ENV SKIP_COMPOSER 1
ENV PHP_ERRORS_STDERR 1
ENV RUN_SCRIPTS 1
ENV REAL_IP_HEADER 1
ENV APP_ENV=production
ENV APP_DEBUG=false
ENV LOG_CHANNEL=stderr
ENV PHP_ERRORS_STDERR=1

EXPOSE 80
# CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]

# Start both PHP-FPM and Nginx using Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
