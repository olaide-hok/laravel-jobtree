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

# 1. Install system dependencies with build tools
RUN apk update && \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
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
        libwebp-dev && \
    apk add --no-cache \
        icu-dev \
        postgresql-dev \
        linux-headers

# 2. Install and configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) \
        zip \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        intl && \
    pecl install redis && docker-php-ext-enable redis && \
    apk del .build-deps

# 3. Install Composer (latest version)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Configure PHP settings
RUN echo "memory_limit = -1" > /usr/local/etc/php/conf.d/memory-limit.ini && \
    echo "opcache.enable_cli = 1" > /usr/local/etc/php/conf.d/opcache.ini

# Copy custom NGINX config
COPY /conf/default.conf /etc/nginx/sites-available/default.conf

WORKDIR /var/www/html

# 5. Prepare directory structure with correct permissions
RUN mkdir -p \
        storage/framework/{cache,sessions,testing,views} \
        storage/logs \
        bootstrap/cache && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 storage bootstrap/cache

# 6. Copy only composer files first for caching
COPY composer.json composer.lock ./

# 7. Install dependencies with verbose output
RUN composer install \
    --optimize-autoloader \
    --no-dev \
    --no-interaction \
    --no-progress \
    --no-scripts \
    -vvv

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
