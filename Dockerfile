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

RUN useradd -m wp && chown -R wp:wp /home/wp

COPY setup.sh oauth.php /

RUN php -l /oauth.php && bash -n /setup.sh

RUN mkdir -p /var/www/html/wp-content/uploads && \
  chown -R wp:wp /var/www/html && \
  chown wp:www-data /var/www/html/wp-content/uploads && \
  chmod g+ws /var/www/html/wp-content/uploads

VOLUME /var/www/html /var/www/html/wp-content/uploads
WORKDIR /var/www/html

USER wp

ENTRYPOINT [ "bash" ]
CMD [ "-c", ". /setup.sh; setup" ]
