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

# Copy custom NGINX config
COPY /conf/default.conf /etc/nginx/sites-available/default.conf

WORKDIR /var/www/html

# 1. Copy composer files first
COPY composer.json composer.lock ./

# 2. Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction --no-progress

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
