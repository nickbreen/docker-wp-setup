#!/bin/bash

function install_core {
	# Download the lastest WP, preferebly with the selected locale, but fall back to the default locale.
	wp core download ${WP_LOCALE:+--locale="$WP_LOCALE"} ${WP_VERSION:+--version="$WP_VERSION"} || wp core download || true

	local V=$(shopt -qo xtrace && echo "-vvv")
	# Setup the database if required.
	local SQL="CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; CREATE USER '$WP_DB_USER' IDENTIFIED BY '$WP_DB_PASSWORD'; GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO '$WP_DB_USER';	FLUSH PRIVILEGES; SHOW GRANTS FOR \"$WP_DB_USER\""
	echo Waiting for the server at $WP_DB_HOST
	while ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -u$WP_DB_ROOT_USER -p$WP_DB_ROOT_PASSWORD -e "SELECT VERSION();"; do sleep 5; done
	echo Checking the DB $WP_DB_NAME and USER $WP_DB_USER is available.
	if ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -u$WP_DB_USER -p$WP_DB_PASSWORD $WP_DB_NAME -e "SELECT DATABASE(), USER();"
	then
		echo Set up the DB $WP_DB_NAME and USER $WP_DB_USER.
		while ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -u$WP_DB_ROOT_USER -p$WP_DB_ROOT_PASSWORD -e "$SQL"; do sleep 5; done
	fi

	if [ $WP_SUBDOMAINS ]
	then
		EXTRA_PHP=$(cat <<-EOF
		if (isset(\$_SERVER['HTTP_HOST']))
			define('COOKIE_DOMAIN', preg_replace('/^www/', '', \$_SERVER['HTTP_HOST']));
		define('MULTISITE', true);
		define('SUBDOMAIN_INSTALL', true);
		define('DOMAIN_CURRENT_SITE', '${WP_URL##*//}');
		define('PATH_CURRENT_SITE', '/');
		define('SITE_ID_CURRENT_SITE', 1);
		define('BLOG_ID_CURRENT_SITE', 1);
		EOF
		)
	fi

	# Configure the database
	wp core config \
			${WP_LOCALE:+--locale="$WP_LOCALE"} \
			--dbname="${WP_DB_NAME}" \
			--dbuser="${WP_DB_USER}" \
			--dbpass="${WP_DB_PASSWORD}" \
			--dbhost="${WP_DB_HOST}:${WP_DB_PORT}" \
			${WP_DB_PREFIX:+--dbprefix="$WP_DB_PREFIX"} \
			--extra-php <<< "${WP_EXTRA_PHP}${EXTRA_PHP}" \
		|| true

	# Configure the Blog
	wp --url="$WP_URL" core is-installed || wp core ${WP_SUBDOMAINS:+multisite-}install \
			--url="$WP_URL" \
			${WP_SUBDOMAINS:+--subdomains} \
			--title="$WP_TITLE" \
			--admin_user="$WP_ADMIN_USER" \
			--admin_password="$WP_ADMIN_PASSWORD" \
			--admin_email="$WP_ADMIN_EMAIL" \
			--skip-email
}

# setup a new site
function new_site {
	local SLUG=$1 DOMAIN=$2 URL=$3 TITLE=$4 ID
	ID=$(wp site list --field=blog_id --domain=$DOMAIN)
	if [ ! $ID ]
	then
		ID=$(wp site create --slug=$SLUG --title="$TITLE" --porcelain)
		wp db query "UPDATE wp_blogs SET domain = '$DOMAIN' WHERE blog_id = $ID"
	fi
	wp --url=$URL option update siteurl $URL
	wp --url=$URL option update home $URL
}

# Allows execution of arbitrary WP-CLI commands.
# I suppose this is either quite dangerous and makes most of
# the rest of this script redundant.
function wp_commands {
	for V in ${!WP_COMMANDS*}
	do
		eval "${!V}"
	done
}

# All rolled up into one function.
function setup {
	install_core
	wp_commands
}

# Juggle ENV VARS
: ${WP_DB_ROOT_USER:=root}
: ${WP_DB_ROOT_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
: ${WP_DB_NAME:=$MYSQL_ENV_MYSQL_DATABASE}
: ${WP_DB_USER:=$MYSQL_ENV_MYSQL_USER}
: ${WP_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
: ${WP_DB_HOST:=$MYSQL_PORT_3306_TCP_ADDR}
: ${WP_DB_PORT:=${MYSQL_PORT_3306_TCP_PORT:-3306}}
: ${WP_SUBDOMAINS:-no}
: ${WP_URL:? is required}
: ${WP_TITLE:? is required}
: ${WP_ADMIN_USER:? is required}
: ${WP_ADMIN_PASSWORD:? is required}
: ${WP_ADMIN_EMAIL:? is required}
