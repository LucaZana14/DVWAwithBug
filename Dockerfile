FROM docker.io/library/php:8-apache

LABEL org.opencontainers.image.source=https://github.com/digininja/DVWA
LABEL org.opencontainers.image.description="DVWA pre-built image."
LABEL org.opencontainers.image.licenses="gpl-3.0"

WORKDIR /var/www/html

# Installazione dipendenze di sistema
RUN apt-get update \
 && export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y zlib1g-dev libpng-dev libjpeg-dev libfreetype6-dev iputils-ping git unzip \
 && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-jpeg --with-freetype \
 && a2enmod rewrite \
 && docker-php-ext-install gd mysqli pdo pdo_mysql

# Installazione Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Copia dei file e configurazione permessi
COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data config/config.inc.php.dist config/config.inc.php

# Installazione dipendenze API (DVWA utilizza Slim framework qui)
# Aggiungiamo 'unzip' sopra e usiamo --no-dev per risparmiare memoria
RUN cd /var/www/html/vulnerabilities/api \
    && php -d memory_limit=-1 /usr/local/bin/composer install \
    --no-interaction --no-progress --no-dev --optimize-autoloader \
    2>&1 || (echo "Retry con swap..." && \
    fallocate -l 512M /swapfile && chmod 600 /swapfile && \
    mkswap /swapfile && swapon /swapfile && \
    php -d memory_limit=-1 /usr/local/bin/cßomposer install \
    --no-interaction --no-progress --no-dev && \
    swapoff /swapfile && rm /swapfile)