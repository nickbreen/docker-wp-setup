#!/bin/bash

X=$(shopt -qo xtrace && echo "-x")

# Juggle ENV VARS
echo MYSQL_ROOT_PASSWORD = ${MYSQL_ROOT_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
echo WP_DB_NAME = ${WP_DB_NAME:=$MYSQL_ENV_MYSQL_DATABASE}
echo WP_DB_USER = ${WP_DB_USER:=$MYSQL_ENV_MYSQL_USER}
echo WP_DB_PASSWORD = ${WP_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
echo WP_DB_HOST = ${WP_DB_HOST:=$MYSQL_PORT_3306_TCP_ADDR}
echo WP_DB_PORT = ${WP_DB_PORT:=${MYSQL_PORT_3306_TCP_PORT:-3306}}
echo WP_NETWORK = ${WP_NETWORK:-no}
echo WP_SUBDOMAINS = ${WP_SUBDOMAINS:-no}
echo WP_URL = ${WP_URL:?WP_URL is required}

function install_core {
	# Download the lastest WP, preferebly with the selected locale, but fall back to the default locale.
	wp core download ${WP_LOCALE:+--locale="$WP_LOCALE"} || wp core download || true

	local V=$(shopt -qo xtrace && echo "-vvv")
	# Setup the database if required.
	local SQL="CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; CREATE USER '$WP_DB_USER' IDENTIFIED BY '$WP_DB_PASSWORD'; GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO '$WP_DB_USER';	FLUSH PRIVILEGES; SHOW GRANTS FOR \"$WP_DB_USER\""
	echo Waiting for the server at $WP_DB_HOST
	while ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT VERSION();"; do sleep 5; done
	echo Checking the DB $WP_DB_NAME and USER $WP_DB_USER is available.
	if ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -u$WP_DB_USER -p$WP_DB_PASSWORD $WP_DB_NAME -e "SELECT DATABASE(), USER();"
	then
		echo Set up the DB $WP_DB_NAME and USER $WP_DB_USER.
		while ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -uroot -p$MYSQL_ROOT_PASSWORD -e "$SQL"; do sleep 5; done
	fi

	# Configure the database
	wp core config \
			${WP_LOCALE:+--locale="$WP_LOCALE"} \
			--dbname="${WP_DB_NAME}" \
			--dbuser="${WP_DB_USER}" \
			--dbpass="${WP_DB_PASSWORD}" \
			--dbhost="${WP_DB_HOST}:${WP_DB_PORT}" \
			${WP_DB_PREFIX:+--dbprefix="$WP_DB_PREFIX"} \
			--extra-php <<< "${WP_EXTRA_PHP}" \
		|| true

	# Configure the Blog
	wp core is-installed || wp core ${WP_SUBDOMAINS:+multisite-}install \
			--url="$WP_URL" \
			${WP_SUBDOMAINS:+--subdomains} \
			--title="$WP_TITLE" \
			--admin_user="$WP_ADMIN_USER" \
			--admin_password="$WP_ADMIN_PASSWORD" \
			--admin_email="$WP_ADMIN_EMAIL" \
			--skip-email
}

# Allows execution of arbitrary WP-CLI commands.
# I suppose this is either quite dangerous and makes most of
# the rest of this script redundant.
# Use this carefully as it, rather xargs, will process quotes.
# If you command contains quotes they shall not pass! Without escaping that is.
function wp_commands {
	for V in ${!WP_COMMANDS*}
	do
		xargs -r -L 1 wp <<< "${!V}"
	done
}

function import {
	wp plugin is-installed wordpress-importer || install_a plugin wordpress-importer
	# wp option update siteurl "$WP_URL"
	# wp option update home "$WP_URL"
	echo 'Importing, this may take a *very* long time.'
	wp import $WP_IMPORT --authors=create --skip=image_resize --quiet "$@"
}

# All rolled up into one function.
function setup {
	install_core
	wp_commands
}
