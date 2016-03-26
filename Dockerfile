FROM nickbreen/wp-cli:v1.1.0

MAINTAINER Nick Breen <nick@foobar.net.nz>

ENV WP_DB_ROOT_USER="root" \
    WP_DB_ROOT_PASSWORD="" \
    WP_LOCALE="" \
    WP_DB_HOST="" \
    WP_DB_PORT="" \
    WP_DB_NAME="" \
    WP_DB_USER="" \
    WP_DB_PASSWORD="" \
    WP_DB_PREFIX="" \
    WP_SUBDOMAINS="" \
    WP_URL="" \
    WP_TITLE="" \
    WP_ADMIN_USER="" \
    WP_ADMIN_PASSWORD="" \
    WP_ADMIN_EMAIL="" \
    WP_EXTRA_PHP=""

RUN mkdir -p /usr/local/share/php/
COPY php/* /usr/local/share/php/

COPY setup.sh /etc/profile.d/

RUN for f in /usr/local/share/php/*.php; do php -l $f; done && bash -n /etc/profile.d/setup.sh

RUN useradd -M -N -g www-data -d /var/www -s /bin/bash wp

WORKDIR /var/www

RUN mkdir -p wp-content/uploads && \
  chown -R wp:www-data . && \
  chmod -R g-w . && \
  chmod -R g+w wp-content/uploads

COPY wp-cli.yml /

VOLUME /var/www /var/www/wp-content/uploads
