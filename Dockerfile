FROM php:5.6-apache

LABEL maintainer="GeoKrety Team <contact@geokrety.org>"

ARG SMARTY_VERSION=2.6.30
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
    && docker-php-ext-install gettext mysqli mcrypt pdo_mysql \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && a2enmod rewrite \
    \
    && echo 'date.timezone = "${TIMEZONE}"' > /usr/local/etc/php/conf.d/timezone.ini \
    && echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini \
    \
    && mkdir /usr/share/php \
    && curl -sS -L https://github.com/smarty-php/smarty/archive/v${SMARTY_VERSION}.tar.gz | tar xzf - -C /usr/share/php/ \
    && ln -s /usr/share/php/smarty-${SMARTY_VERSION} /usr/share/php/smarty \
    \
    && cd /usr/share/php/smarty/libs/plugins/ \
    && curl -sS -L -O https://raw.githubusercontent.com/smarty-gettext/smarty-gettext/master/block.t.php \
    && curl -sS -L -O https://github.com/smarty-gettext/smarty-gettext/raw/master/function.locale.php \
    && chmod a+r /usr/share/php/smarty/libs/plugins/block.t.php /usr/share/php/smarty/libs/plugins/function.locale.php \
    && cd \
    \
    && curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin/ \
    \
    && locale-gen

# Install site
ONBUILD ARG GIT_COMMIT='unspecified'
ONBUILD ADD --chown=www-data:www-data website/ /var/www/html/
ONBUILD RUN composer install --no-scripts \
    && echo $GIT_COMMIT > /var/www/html/git-version
