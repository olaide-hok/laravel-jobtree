# Stage 1: Build assets
FROM node:22 as node-build
WORKDIR /app
COPY . .
RUN npm install && npm run build

# Stage 2: Composer dependencies
FROM php:8.4-fpm as php-build
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    git unzip curl libzip-dev libpq-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql zip bcmath opcache

COPY --from=node-build /app /app
COPY --from=node-build /app/public /app/public

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --optimize-autoloader --no-dev

# Stage 3: Production container
FROM nginx:1.25-alpine
WORKDIR /var/www/html

# Copy app from PHP build stage
COPY --from=php-build /app /var/www/html

# Add nginx config
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# PHP-FPM setup
COPY --from=php-build /usr/local/etc/php-fpm.d/ /usr/local/etc/php-fpm.d/
COPY --from=php-build /usr/local/bin/php /usr/local/bin/php
COPY --from=php-build /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm

# Image config
ENV SKIP_COMPOSER 1
ENV PHP_ERRORS_STDERR 1
ENV RUN_SCRIPTS 1
ENV REAL_IP_HEADER 1

# Laravel ENV Settings
ENV APP_ENV=production
ENV APP_DEBUG=false
ENV LOG_CHANNEL=stderr
ENV PHP_ERRORS_STDERR=1

# Laravel: Cache config, routes, views
RUN php artisan config:cache && \
 php artisan route:cache && \
 php artisan view:cache && \
 php artisan storage:link

CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
