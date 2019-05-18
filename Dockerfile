FROM php:5.6-apache

LABEL maintainer="GeoKrety Team <contact@geokrety.org>"

ARG SMARTY_VERSION=3.1.33
ARG TIMEZONE=Europe/Paris

# Configure
COPY files/ /

# Add extension to php
RUN apt-get update \
    && apt-get install -y \
       	libmagickwand-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        graphicsmagick-imagemagick-compat \
        ssmtp \
        locales \
        gettext \
        vim \
        curl \
        git \
        zip \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* \
    \
    && docker-php-ext-install gettext mysqli mcrypt pdo_mysql bz2 \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && a2enmod rewrite \
    \
    && pecl install -o -f redis-4.3.0 \
    &&  rm -rf /tmp/pear \
    && docker-php-ext-enable redis \
    \
    && echo 'date.timezone = "${TIMEZONE}"' > /usr/local/etc/php/conf.d/timezone.ini \
    && echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini \
    && echo 'upload_max_filesize = 8M' > /usr/local/etc/php/conf.d/upload.ini \
    \
    && curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin/ \
    \
    && locale-gen

# Install site
ONBUILD ARG GIT_COMMIT='unspecified'
ONBUILD ADD --chown=www-data:www-data website/ /var/www/html/
ONBUILD RUN composer install --no-scripts \
    && echo $GIT_COMMIT > /var/www/html/git-version
