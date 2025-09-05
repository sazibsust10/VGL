# Build PHP dependencies
FROM composer:2 AS composer

# Runtime: PHP-FPM with Nginx
FROM php:8.3-fpm-alpine AS php

RUN apk add --no-cache bash nginx supervisor libpq-dev libzip-dev icu-dev oniguruma-dev     && docker-php-ext-install pdo pdo_mysql intl zip opcache

# PHP config
COPY docker/php/conf.d/app.ini /usr/local/etc/php/conf.d/app.ini

# App
WORKDIR /app
COPY . /app

# Install PHP deps if composer.json exists
RUN if [ -f composer.json ]; then       php -v &&       curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer &&       composer install --no-interaction --prefer-dist;     fi

# Nginx
RUN mkdir -p /run/nginx
COPY docker/backend/nginx.conf /etc/nginx/nginx.conf

# Supervisor to run php-fpm + nginx
RUN printf '[supervisord]\nnodaemon=true\n[program:php-fpm]\ncommand=php-fpm\n[program:nginx]\ncommand=nginx -g "daemon off;"\n' > /etc/supervisord.conf

EXPOSE 8080
CMD ["sh", "-c", "sed -i 's|API_BASE|${APP_URL:-http://localhost}|g' /etc/nginx/nginx.conf; exec supervisord -c /etc/supervisord.conf"]
