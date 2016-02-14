FROM nickbreen/wp-cli

MAINTAINER Nick Breen <nick@foobar.net.nz>

ENV MYSQL_ROOT_PASSWORD="" \
    WP_LOCALE="" \
    WP_DB_HOST="" \
    WP_DB_PORT="" \
    WP_DB_NAME="" \
    WP_DB_USER="" \
    WP_DB_PASSWORD="" \
    WP_DB_PREFIX="" \
    WP_URL="" \
    WP_TITLE="" \
    WP_ADMIN_USER="" \
    WP_ADMIN_PASSWORD="" \
    WP_ADMIN_EMAIL="" \
    WP_THEMES="" \
    BB_THEMES="" \
    WP_PLUGINS="" \
    BB_PLUGINS="" \
    WP_OPTIONS="" \
    WP_IMPORT="" \
    WP_EXTRA_PHP=""

RUN mkdir -p /usr/local/share/php/
COPY oauth.php php/* /usr/local/share/php/

COPY setup.sh /etc/profile.d/

RUN for f in /usr/local/share/php/*.php; do php -l $f; done && bash -n /etc/profile.d/setup.sh

RUN useradd -M -N -g www-data -d /var/www -s /bin/bash wp

RUN mkdir -p /var/www/wp-content/uploads && \
  chown -R wp:www-data /var/www && \
  chmod -R g-w /var/www && \
  chmod -R g+w /var/www/wp-content/uploads

VOLUME /var/www /var/www/wp-content/uploads

WORKDIR /var/www
