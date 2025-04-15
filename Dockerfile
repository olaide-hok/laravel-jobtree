# Stage 1: Build frontend assets
FROM node:22 as node-build
WORKDIR /app
COPY . .
RUN npm install && npm run build

# Stage 2: PHP + Nginx + Laravel
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    git \
    unzip \
    curl \
    zip \
    supervisor \
    libzip-dev \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath opcache

# Set working directory
WORKDIR /var/www/html

# Copy Laravel app
COPY . .

# Copy built frontend assets
COPY --from=node-build /app/public /var/www/html/public

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev

# Laravel setup
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan storage:link

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Nginx configuration
COPY ./conf/default.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Supervisor configuration
COPY ./conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose web server port
EXPOSE 80

# Start PHP-FPM and Nginx via Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
