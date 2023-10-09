FROM php:8.2-apache

LABEL maintainer="IFDD"

USER root

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    nano \
    git \
    libpng-dev \
    zlib1g-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    zip \
    curl \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    nodejs \
    npm \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure gd \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install exif \
    && docker-php-ext-install zip \
    && apt install libgmp-dev -y \
    && docker-php-ext-install gmp \
    && docker-php-ext-install intl \
    && docker-php-ext-install bcmath \
    && docker-php-source delete

RUN apt-get install -y apache2

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN rm -rf /var/www/html/ifdd-services/ || true
RUN git clone https://github.com/GeOsmFamily/ifdd-services.git ./ifdd-services
RUN cd /var/www/html/ifdd-services && composer install

RUN rm -rf /var/www/html/ifdd-frontend/ || true
RUN git clone https://github.com/GeOsmFamily/ifdd-frontend.git ./ifdd-frontend
RUN cd /var/www/html/ifdd-frontend && npm install

COPY .docker/vhosts/service.conf /etc/apache2/sites-available/service.conf
COPY .docker/vhosts/frontend.conf /etc/apache2/sites-available/frontend.conf
COPY .docker/htaccess.txt /var/www/html/ifdd-frontend/htaccess.txt
RUN  mkdir -p /var/www/html/ifdd-services/storage/app/analytics
COPY .docker/service-account-credentials.json /var/www/html/ifdd-services/storage/app/analytics/service-account-credentials.json
COPY .docker/install.sh /var/www/html/install.sh
RUN  chmod +x /var/www/html/install.sh 
COPY .docker/update.sh /var/www/html/update.sh
RUN  chmod +x /var/www/html/update.sh
COPY .docker/.env /var/www/html/.env

RUN chown -R www-data:www-data /var/www/html/ifdd-services \
    && a2enmod rewrite
