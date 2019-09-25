FROM php:7.3-apache-stretch

LABEL maintainer="GeoKrety Team <contact@geokrety.org>"

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
        libxslt-dev \
        libcurl4-openssl-dev \
        libssl-dev \
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
    && docker-php-ext-install gettext mysqli pdo_mysql bz2 xsl \
    && pecl install raphf propro \
    && docker-php-ext-enable raphf propro \
    && pecl install imagick mcrypt-1.0.2 pecl_http \
    && docker-php-ext-enable imagick mcrypt http \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && a2enmod rewrite \
    \
    && pecl install -o -f redis \
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

WORKDIR /var/www/geokrety/website
# Install site
ONBUILD ARG GIT_COMMIT='undef'
ONBUILD ADD --chown=www-data:www-data . /var/www/geokrety/
ONBUILD RUN composer global install --no-scripts -d /var/www/geokrety \
    && composer install --no-scripts -d /var/www/geokrety/website
