FROM php:8.5.0alpha4-fpm-bullseye

LABEL maintainer="GeoKrety Team <contact@geokrety.org>"

ARG TIMEZONE=Europe/Paris

# Add extension to php
RUN apt-get update \
    && apt-get install -y \
        curl \
        gettext \
        git \
        graphicsmagick-imagemagick-compat \
        httping \
        libcurl4-openssl-dev \
        libfcgi-bin \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libpng-dev \
        libpq-dev \
        libssl-dev \
        libxslt-dev \
        libzip-dev \
        locales \
        msmtp \
        postgresql-client \
        vim \
        wget \
        zip \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* \
    \
    && echo "set mouse-=a" > /root/.vimrc \
    && echo "syn on" >> /root/.vimrc

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
# See https://github.com/Imagick/imagick/issues/643#issuecomment-2086949716
RUN install-php-extensions \
        Imagick/imagick@ffa23eb0bc6796349dce12a984b3b70079e7bdd3 \
    \
    && docker-php-ext-install bcmath gettext mysqli pdo_mysql pgsql pdo_pgsql bz2 xsl pcntl \
    && pecl install raphf \
    && docker-php-ext-enable raphf pcntl \
    && pecl install mcrypt pecl_http \
    && docker-php-ext-enable mcrypt http \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install opcache \
    && docker-php-ext-install sockets \
    && docker-php-ext-install zip \
    \
    && pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    && docker-php-ext-enable redis \
    \
    && echo 'date.timezone = "${TIMEZONE}"' > /usr/local/etc/php/conf.d/timezone.ini \
    && echo 'sendmail_path = "/usr/sbin/msmtp -t"' > /usr/local/etc/php/conf.d/mail.ini \
    && echo 'upload_max_filesize = 8M' > /usr/local/etc/php/conf.d/upload.ini \
    \
    && curl -sSL https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin/ \
    \
    && curl -sSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc \
    && chmod +x /usr/local/bin/mc \
    \
    && curl -sSL https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck -o /usr/local/bin/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck \
    \
    && echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf \
    && echo "pm.max_children = 10" >> /usr/local/etc/php-fpm.d/zz-docker.conf

# Configure
COPY files/etc/locale.gen /etc/locale.gen
RUN locale-gen

# Install other files
COPY files/ /

# Install site
ONBUILD ARG GIT_COMMIT='undef'
