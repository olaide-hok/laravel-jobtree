# ---------------------------
# Build Stage (Node + Assets)
# ---------------------------
FROM node:22 as build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# -------------------------------
# Final Stage (PHP + NGINX-FPM)
# -------------------------------
FROM richarvey/nginx-php-fpm:3.1.6

# Install system dependencies (Alpine-compatible)
RUN apk update && \
    apk add --no-cache \
        git \
        curl \
    libzip-dev \
    zip \
    unzip \
    libpng-dev \
    libxml2-dev \
    oniguruma-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
      g++ \
    make \
    autoconf && \
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

# Install proper Composer version
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy custom NGINX config
COPY /conf/default.conf /etc/nginx/sites-available/default.conf

WORKDIR /var/www/html

# Set permissions before composer install
RUN mkdir -p vendor && chown -R www-data:www-data .

# 1. Copy composer files first
COPY composer.json composer.lock ./

# 2. Install PHP dependencies with increased memory limit
RUN php -d memory_limit=-1 /usr/bin/composer install \
    --optimize-autoloader \
    --no-dev \
    --no-interaction \
    --no-progress

# 3. Copy application
COPY . .

# 4. Copy ONLY built assets
COPY --from=build /app/public/build /var/www/html/public/build

# 5. Set permissions
RUN chown -R www-data:www-data storage bootstrap/cache

# 6. Environment
ENV WEBROOT=/var/www/html/public \
    SKIP_COMPOSER=1 \
    PHP_ERRORS_STDERR=1 \
    RUN_SCRIPTS=1 \
    REAL_IP_HEADER=1 \
    APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    COMPOSER_ALLOW_SUPERUSER=1

# 7. Cache setup
RUN php artisan config:clear && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan storage:link

CMD ["/start.sh"]
