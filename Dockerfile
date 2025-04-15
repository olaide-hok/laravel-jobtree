# ---------------------------
# Build Stage (Node + Assets)
# ---------------------------
FROM node:22 as build

# Set workdir
WORKDIR /app

# Copy only package.json first for caching
COPY package*.json ./
RUN npm install

# Copy everything and build assets
COPY . .
RUN npm run build


# -------------------------------
# Final Stage (PHP + NGINX-FPM)
# -------------------------------
FROM richarvey/nginx-php-fpm:3.1.6

# Set working directory
WORKDIR /var/www/html

# Copy app source
COPY --from=build /app /var/www/html

# Set Laravel web root
ENV WEBROOT /var/www/html/public

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

# Allow composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER=1

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev

# Laravel: Cache config, routes, views
RUN php artisan config:cache && \
 php artisan route:cache && \
 php artisan view:cache

# Expose default web port
EXPOSE 80

# Start container
CMD ["/start.sh"]
