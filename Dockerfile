FROM php:7-apache

ENV APP_ENV production

RUN mkdir -p /usr/src/app
RUN sed -i 's!/var/www/html!/usr/src/app/public!g' /etc/apache2/apache2.conf
WORKDIR /usr/src/app

RUN apt-get update && \
apt-get install -y git zip unzip zlib1g-dev && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-ext-install pdo_mysql zip
RUN a2enmod rewrite

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
php -r "unlink('composer-setup.php');"

COPY ./composer.json /usr/src/app/composer.json
COPY ./composer.lock /usr/src/app/composer.lock
COPY ./database /usr/src/app/database
RUN composer install

ADD . /usr/src/app
RUN php artisan optimize

RUN touch /usr/src/app/storage/logs/laravel.log
RUN chmod -R 777 /usr/src/app

RUN sed -i 's!/var/www/html!/usr/src/app/public!g' /etc/apache2/sites-enabled/000-default.conf
RUN sed -i 's!<Directory /var/www/>!<Directory /usr/src/app/public>!g' /etc/apache2/apache2.conf
