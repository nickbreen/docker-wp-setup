#!/bin/bash

# Juggle ENV VARS
echo MYSQL_ROOT_PASSWORD = ${MYSQL_ROOT_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
echo WP_DB_NAME = ${WP_DB_NAME:=$MYSQL_ENV_MYSQL_DATABASE}
echo WP_DB_USER = ${WP_DB_USER:=$MYSQL_ENV_MYSQL_USER}
echo WP_DB_PASSWORD = ${WP_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
echo WP_DB_HOST = ${WP_DB_HOST:=$MYSQL_PORT_3306_TCP_ADDR}
echo WP_DB_PORT = ${WP_DB_PORT:=$MYSQL_PORT_3306_TCP_PORT}

# Installs themes or plugins from a list on STDIN.
#
# STDIN format each line: slug [URL]
# E.g.
#   hello-dolly
#   wordpress-importer
#   some-other-plugin http://some.other/plugin.zip
#
# Usage:
#   install_a plugin <<< "plugin_slug|plugin_url"
#   install_a theme <<-EOT
#     theme_slug1
#     http://theme_url2
#   EOT
#
function install_a {
	while read SLUG
	do
		wp $1 is-installed $SLUG || wp $1 install $SLUG --activate
	done
}

# Installs themes or plugins specified on STDIN hosted at BitBucket.
# Usage:
#   install_b plugin|theme <<< "REPO TAG"
#
# REPO is the account/repository.
# TAG is optionally any tag|branch|commitish
#
# Requires $BB_KEY and $BB_SECRET environment variables.
#
function install_b {
	local URL="https://bitbucket.org/${2}/get/${3:-master}.tar.gz"
	TGZ=$(php /oauth.php -O -k "$BB_KEY" -s "$BB_SECRET" -- $URL)
	install_tgz $1 $TGZ
}

# Installs themes or plugins specified on STDIN hosted at GitHub.
# Usage:
#   install_g plugin|theme <<< "REPO [TAG]"
#
# REPO is the account/repository.
# TAG is optionally any release|tag|branch|commitish
#
# Will authenticate with GitHub if a GH_TOKEN environment variable exists.
#
function install_g {
	# Get the tarball URL for the latest (or specified release)
	local URL=$(curl -sfL ${GH_TOKEN:+-u $GH_TOKEN} "https://api.github.com/repos/${2}/releases/${3:-latest}" | jq -r '.tarball_url')
	# If no releases are available fail-back to a commitish
	: ${URL:=https://api.github.com/repos/${2}/tarball/${3:-master}}
	TGZ=$(curl -sfLJO ${GH_TOKEN:+-u $GH_TOKEN} -w '%{filename_effective}' $URL)
	install_tgz $1 $2 $TGZ
}

# Extract the tarball and re-zip (store only) using the canonicalised name.
# This assumes that the project name is the canonical name for the theme
# or plugin! This may not actually be the case! If not then we'll need to
# specify a SLUG.
function install_tgz {
	local TMP=$(mktemp -d)
	mkdir -p $TMP/${2##*/}
	tar xzf $3 --strip-components 1 -C $TMP/${2##*/} && rm $3
	( cd $TMP; zip -0qrm ${2##*/}.zip ${2##*/} )
	wp $1 install $TMP/${2##*/}.zip --force --activate
	rm -rf $TMP
}

function install_core {
	# Setup the database
	# Wait for the MySQL server
	while ! mysql -h$WP_DB_HOST -P$WP_DB_PORT -uroot -p$MYSQL_ROOT_PASSWORD; do sleep 5; done
	# The local mysql seems to hang and go defunct! TODO fix!
	local SQL="CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO \"$WP_DB_USER\" IDENTIFIED BY \"$WP_DB_PASSWORD\";	FLUSH PRIVILEGES; SHOW GRANTS FOR \"$WP_DB_USER\""
	local PHP='
		$mysqli = new mysqli($_SERVER["WP_DB_HOST"], "root", $_SERVER["MYSQL_ROOT_PASSWORD"], "", $_SERVER["WP_DB_PORT"]);
		if ($mysqli->connect_error) exit(1);
		$mysqli->multi_query($_SERVER["SQL"]);
		do {
			if ($result = $mysqli->use_result()) {
				echo implode(PHP_EOL, $result->fetch_array());
				$result->close();
			}
		} while ($mysqli->next_result());
		$mysqli->close();
	'
	SQL="$SQL" wp eval --skip-wordpress "$PHP"

	# Always download the lastest WP
	wp core download --locale="${WP_LOCALE}" || true

	# Configure the database
	rm -f wp-config.php
	wp core config \
			--locale="${WP_LOCALE}" \
			--dbname="${WP_DB_NAME}" \
			--dbuser="${WP_DB_USER}" \
			--dbpass="${WP_DB_PASSWORD}" \
			--dbhost="${WP_DB_HOST}:${WP_DB_PORT}" \
			--dbprefix="${WP_DB_PREFIX}" \
			--extra-php <<< "${WP_EXTRA_PHP}"

	# Configure the Blog
	wp core is-installed || wp core install \
			--url="$WP_URL" \
			--title="$WP_TITLE" \
			--admin_user="$WP_ADMIN_USER" \
			--admin_password="$WP_ADMIN_PASSWORD" \
			--admin_email="$WP_ADMIN_EMAIL"
}

# Install themes or plugins from env vars
function install_x {
	export -f install_{a,b,g,tgz}
	local X=$(shopt -qo xtrace && echo "-x")
	for V in {WP,GH,BB}_$1
	do
		xargs -r -L 1 bash $X -e -c '"${@}"' _ install_$(echo ${V::1} | tr WGB agb) $2 <<< "${!V}"
	done
}

# Install themes from env vars
function install_themes {
	install_x THEMES theme
}

# Install plugins from env vars
function install_plugins {
	install_x PLUGINS plugin
}

# Sets options as specified in STDIN.
# Expects format of OPTION_NAME JSON_STRING
function wp_options {
	[ -z $WP_OPTIONS ] || while read OPT VALUE
	do
		wp option set --format=json $OPT "$VALUE"
	done <<< "$WP_OPTIONS"
}

# Allows execution of arbitrary WP-CLI commands.
# I suppose this is either quite dangerous and makes most of
# the rest of this script redundant.
function wp_commands {
	xargs -r -L 1 wp <<< "$WP_COMMANDS"
}

function import {
	wp plugin is-installed wordpress-importer || install_a plugin wordpress-importer
	# wp option update siteurl "$WP_URL"
	# wp option update home "$WP_URL"
	echo 'Importing, this may take a *very* long time.'
	wp import $WP_IMPORT --authors=create --skip=image_resize --quiet "$@"
}

# All rrolled up into one function.
function setup {
	install_core
	install_themes
	install_plugins
	wp_options
	wp_commands
}
