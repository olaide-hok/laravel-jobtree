# ---------------------------
# Build Stage (Node + Assets)
# ---------------------------
FROM node:22 as node-build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# ----------------------------
# PHP Dependencies Stage
# ----------------------------
FROM php:8.2-fpm-alpine as php-build

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
git \
curl \
libzip-dev \
unzip \
libpng-dev \
libxml2-dev \
oniguruma-dev \
freetype-dev \
libjpeg-turbo-dev \
libwebp-dev \
g++ \
make \
autoconf \
bash && \
docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
docker-php-ext-install \
zip \
pdo \
pdo_mysql \
mbstring \
exif \
pcntl \
bcmath \
gd

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy Laravel files
COPY . .

# Build PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction --no-progress

# Cache config, routes, views and link storage
RUN php artisan config:cache && \
php artisan route:cache && \
php artisan view:cache && \
php artisan storage:link

# ----------------------------
# Final Image (Nginx + PHP-FPM)
# ----------------------------
FROM richarvey/nginx-php-fpm:3.1.6

ENV WEBROOT=/var/www/html/public

WORKDIR /var/www/html

# Copy Laravel app from build stage
COPY --from=php-build /app /var/www/html

# Copy built frontend assets
COPY --from=node-build /app/public/build /var/www/html/public/build

# Copy nginx config (adjust path if needed)
COPY conf/default.conf /etc/nginx/sites-available/default.conf

# Set proper permissions
RUN chown -R www-data:www-data storage bootstrap/cache

# Set env vars
ENV SKIP_COMPOSER=1 \
PHP_ERRORS_STDERR=1 \
RUN_SCRIPTS=1 \
REAL_IP_HEADER=1 \
APP_ENV=production \
APP_DEBUG=false \
LOG_CHANNEL=stderr \
COMPOSER_ALLOW_SUPERUSER=1

RUN mkdir -p \
    storage/app/public/logos \
    storage/app/public/avatars \
    storage/app/public/resumes && \
    chown -R www-data:www-data storage

RUN chown -R www-data:www-data storage bootstrap/cache

RUN mkdir -p /var/www/html/public && \
    rm -rf /var/www/html/public/storage && \
    ln -s /var/www/html/storage/app/public /var/www/html/public/storage

# Start
CMD ["/start.sh"]
