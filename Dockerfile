FROM ubuntu:10.04
MAINTAINER Brandon Plasters <bmilesp@gmail.com>

RUN apt-get update --fix-missing \
    && apt-get install -y \
        libbz2-dev \
        libpng-dev \
        libcurl4-openssl-dev \
        libltdl-dev \
        libmcrypt-dev \
        libmhash-dev \
        libmysqlclient-dev \
        libpcre3-dev \
#        libpng12-dev \
        libxml2-dev \
        make \
        patch \
        xmlstarlet \
        perl 
#        apache2 
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/*

ADD tmp/ /usr/local/src/
RUN gunzip /usr/local/src/*.gz && tar xf /usr/local/src/php-5.2.16.tar -C /usr/local/src

RUN tar xf /usr/local/src/httpd-2.2.29.tar -C /usr/local/src
RUN cd /usr/local/src/httpd-2.2.29
RUN apt-get install libncurses5-dev
WORKDIR /usr/local/src/httpd-2.2.29
RUN ./configure \
    --enable-so \
    --enable-module=most \
    --enable-rewrite \
    --enable-ssl 
RUN make 
RUN make install

RUN tar xf /usr/local/src/mysql-dfsg-5.1_5.1.73.orig.tar -C /usr/local/src 

RUN apt-get install autoconf -y
#RUN cd /usr/local/src/mysql-dfsg-5.1-5.1.73.orig
#WORKDIR /usr/local/src/mysql-dfsg-5.1-5.1.73.orig

###Configure MYSQL

#RUN ./configure \
#    --prefix=/usr/local/mysql \
#    --with-mysqld-user=www-data \
#    --with-unix-socket-path=/tmp/mysql.socket

### Install

#RUN make 
#RUN make install

RUN cd /usr/local/src/php-5.2.16
WORKDIR /usr/local/src/php-5.2.16
# Apply patches
RUN patch -p1 -i ../suhosin-patch-5.2.16-0.9.7.patch
# Configure PHP
RUN ./configure \
    --with-apxs2=/usr/local/apache2/bin/apxs \
    --enable-mbstring \
    --enable-sockets \
    --enable-bcmath \
    --with-gd \
    --with-gettext \
    --with-libdir \
    --with-libdir=lib64 \
    --with-mcrypt \
    --with-mhash \
    --with-mysql \
    --with-pdo-mysql \
    --with-mysql-sock=/tmp/mysql.socket \
    --with-mysqli \
    --with-openssl \
    --with-pcre-regex \
#    --with-png \
    --with-zlib \
    --with-curl \ 
    --with-pear 
# Install
RUN make 
RUN make install

RUN cp /usr/local/src/php-5.2.16/php.ini-dist /usr/local/lib/php.ini

# Get out of /usr/local/src
RUN cp /usr/local/src/php-5.2.16/php.ini-dist /usr/local/lib/php.ini


RUN mkdir -p /var/www/html && chmod 755 /var/www/html

RUN ls -la /etc

RUN sed -ri 's/^display_errors\s*=\s*Off/display_errors = On/g' /usr/local/lib/php.ini
RUN sed -ri 's/^error_reporting\s*=.*$/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_NOTICE/g' /usr/local/lib/php.ini
RUN sed -ri 's/^error_reporting\s*=.*$/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_NOTICE/g' /usr/local/lib/php.ini

RUN cat /usr/local/apache2/conf/httpd.conf
RUN sed -i "1iServerName localhost" /usr/local/apache2/conf/httpd.conf
RUN sed -i "1iNameVirtualHost *:80" /usr/local/apache2/conf/httpd.conf
RUN sed -i "1iNameVirtualHost *:443" /usr/local/apache2/conf/httpd.conf



#ADD hosts /etc/hosts
#RUN cat /etc/hosts

RUN apt-get install -y 
    nano \
    wget


VOLUME ["/usr/local/apache2/htdocs"]

ADD admin.ugp.conf /etc/apache2/sites-available/admin.ugp.conf
ADD pogo.ugp.conf /etc/apache2/sites-available/pogo.ugp.conf
ADD front.ugp.conf /etc/apache2/sites-available/front.ugp.conf

RUN adduser www-data www-data

RUN sed -i "s/Options FollowSymLinks/Options Indexes FollowSymLinks Includes/g" /usr/local/apache2/conf/httpd.conf
RUN sed -i "s/User daemon/User www-data/g" /usr/local/apache2/conf/httpd.conf
RUN sed -i "s/Group daemon/Group www-data/g" /usr/local/apache2/conf/httpd.conf

RUN sed -i "\$aInclude  /etc/apache2/sites-available/pogo.ugp.conf " /usr/local/apache2/conf/httpd.conf
RUN sed -i "\$aInclude  /etc/apache2/sites-available/admin.ugp.conf " /usr/local/apache2/conf/httpd.conf
RUN sed -i "\$aInclude  /etc/apache2/sites-available/front.ugp.conf " /usr/local/apache2/conf/httpd.conf

RUN chgrp www-data -R /usr/local/apache2/htdocs

RUN sed -i "s/max_execution_time = 30/max_execution_time = 30000/g" /usr/local/lib/php.ini
RUN sed -i "s/extension_dir =.*/extension_dir = \"\/usr\/local\/lib\/php\/extensions\/no-debug-non-zts-20060613\"/g" /usr/local/lib/php.ini
RUN sed -i "s/memory_limit = 128M/memory_limit = 2048M/g" /usr/local/lib/php.ini
RUN sed -i "\$aextension=php_pdo.so" /usr/local/lib/php.ini
RUN sed -i "\$aextension=php_pdo_mysql.so" /usr/local/lib/php.ini

RUN sed -i "\$aAddHandler php5-script .php" /usr/local/apache2/conf/httpd.conf
#RUN sed -i "\$aAddType application/x-http-php .php" /usr/local/apache2/conf/httpd.conf
RUN sed -i "\$aAddType text/html .php" /usr/local/apache2/conf/httpd.conf
RUN sed -i "\$aDirectoryIndex index.html index.php" /usr/local/apache2/conf/httpd.conf


#add mongo driver
WORKDIR /usr/local/src
RUN cd /usr/local/src 

RUN tar xf /usr/local/src/mongo-php-driver-1.5.8.tar -C /usr/local/src \
    && cd mongo-php-driver-1.5.8
WORKDIR /usr/local/src/mongo-php-driver-1.5.8
RUN ls -la 
RUN phpize \
    && ./configure \
    && make all \
    && make install

RUN sed -i "\$aextension=mongo.so" /usr/local/lib/php.ini

ADD dummy.crt /etc/apache2/
ADD dummy.key /etc/apache2/

ADD run /usr/local/bin/ 
RUN chmod +x /usr/local/bin/run

ENV TERM xterm
EXPOSE 80 443
CMD ["/usr/local/bin/run"]