#!/bin/bash

function wp_db_setup {
	: ${WP_DB_HOST:=$MYSQL_PORT_3306_TCP_ADDR}
	: ${WP_DB_PORT:=${MYSQL_PORT_3306_TCP_PORT:-3306}}
	: ${WP_DB_NAME:=$MYSQL_ENV_MYSQL_DATABASE}
	: ${WP_DB_USER:=$MYSQL_ENV_MYSQL_USER}
	: ${WP_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
	: ${WP_DB_ROOT_USER:=root}
	: ${WP_DB_ROOT_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}

	: ${WP_DB_HOST:=? is required}
	: ${WP_DB_PORT:=? is required}
	: ${WP_DB_NAME:=? is required}
	: ${WP_DB_USER:=? is required}
	: ${WP_DB_PASSWORD:=? is required}
	: ${WP_DB_ROOT_USER:=? is required}
	: ${WP_DB_ROOT_PASSWORD:=? is required}

	local V=$(shopt -qo xtrace && echo "-vvv")
	# Setup the database if required.
	local SQL="CREATE DATABASE IF NOT EXISTS \`$WP_DB_NAME\`; GRANT ALL PRIVILEGES ON \`$WP_DB_NAME\`.* TO \`$WP_DB_USER\` IDENTIFIED BY '$WP_DB_PASSWORD';	FLUSH PRIVILEGES; SHOW GRANTS FOR \`$WP_DB_USER\`"
	echo Waiting for the server at $WP_DB_HOST
	while ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -u$WP_DB_ROOT_USER -p$WP_DB_ROOT_PASSWORD -e "SELECT VERSION();"; do sleep 5; done
	echo Checking the DB $WP_DB_NAME and USER $WP_DB_USER is available.
	if ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -u$WP_DB_USER -p$WP_DB_PASSWORD $WP_DB_NAME -e "SELECT VERSION(), DATABASE(), USER();"
	then
		echo Set up the DB $WP_DB_NAME and USER $WP_DB_USER.
		while ! mysql $V -h$WP_DB_HOST -P$WP_DB_PORT -u$WP_DB_ROOT_USER -p$WP_DB_ROOT_PASSWORD -e "$SQL"; do sleep 5; done
	fi
}

function wp_core_download {
	wp core download ${WP_LOCALE:+--locale="$WP_LOCALE"} ${WP_VERSION:+--version="$WP_VERSION"}
}

function wp_core_config {

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

	: ${WP_DB_HOST:=$MYSQL_PORT_3306_TCP_ADDR}
	: ${WP_DB_PORT:=${MYSQL_PORT_3306_TCP_PORT:-3306}}
	: ${WP_DB_NAME:=$MYSQL_ENV_MYSQL_DATABASE}
	: ${WP_DB_USER:=$MYSQL_ENV_MYSQL_USER}
	: ${WP_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}

	: ${WP_DB_HOST:=? is required}
	: ${WP_DB_PORT:=? is required}
	: ${WP_DB_NAME:=? is required}
	: ${WP_DB_USER:=? is required}
	: ${WP_DB_PASSWORD:=? is required}

	# Configure the database
	wp core config \
		${WP_LOCALE:+--locale="$WP_LOCALE"} \
		--dbname="${WP_DB_NAME}" \
		--dbuser="${WP_DB_USER}" \
		--dbpass="${WP_DB_PASSWORD}" \
		--dbhost="${WP_DB_HOST}:${WP_DB_PORT}" \
		${WP_DB_PREFIX:+--dbprefix="$WP_DB_PREFIX"} \
		${WP_SALTS:+--skip-salts} \
		--extra-php <<-EOF
		${WP_SALTS}
		${WP_EXTRA_PHP}
		${EXTRA_PHP}
		EOF
}

function wp_core_install {
	: ${WP_URL:? is required}
	: ${WP_TITLE:? is required}
	: ${WP_ADMIN_USER:? is required}
	: ${WP_ADMIN_PASSWORD:? is required}
	: ${WP_ADMIN_EMAIL:? is required}

	# Configure the Blog
	wp core is-installed ${WP_SUBDOMAINS:+--network} || wp core ${WP_SUBDOMAINS:+multisite-}install \
		--url="$WP_URL" \
		${WP_SUBDOMAINS:+--subdomains} \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email
}

# setup a new site
function wp_site_create {
	local SLUG=$1 DOMAIN=$2 URL=$3 TITLE=$4 ADMIN=$5 ID
	ID=$(wp site list --field=blog_id "--domain=$DOMAIN")
	if [ ! $ID ]
	then
		ID=$(wp site create ${SLUG:+--slug=$SLUG} ${TITLE:+--title="$TITLE"} ${ADMIN:+--email="$ADMIN"} --porcelain)
	fi
	wp_site_domain $ID $DOMAIN $URL
}

function wp_site_domain {
	local ID=$1 DOMAIN=$2 URL=$3
	wp db query "UPDATE wp_blogs SET domain = '$DOMAIN' WHERE blog_id = $ID AND domain <> '$DOMAIN'"
	wp --url=$DOMAIN option update siteurl $URL
	wp --url=$DOMAIN option update home $URL
}

function wp_commands {
	for V in ${!WP_COMMANDS*}; do eval "${!V}"; done
}

function wp_sites {
	for V in ${!WP_SITES*}; do eval "${!V}"; done
}

function wp_safecss {
	local GIST=$1 FILE=$2 GH_AUTH=$3
	curl -sSf ${GH_AUTH:+-u $GH_AUTH} $GIST | jq -r ".files[\"$FILE\"].content" | (
		ID=$(wp post list --post_type=safecss --field=ID)
		if [ "$ID" ]
		then
			wp post update "$ID" - --post_title=safecss --post_type=safecss
		else
			wp post create - --post_title=safecss --post_type=safecss
		fi
	)
}

case "${0##*/}" in
	wp-download)
		wp_core_download
		;;

	wp-configure)
		wp_core_config
		;;

	wp-install)
		wp_core_install
		;;

	wp-db-setup)
		wp_db_setup
		;;

	wp-setup)
		wp_core_download &
		wp_db_setup &
		wait
		wp_core_config
		wp_core_install
		wp_commands
		;;

	wp-commands)
		wp_commands
		;;

	wp-sites)
		wp_sites
		;;

	wp-site-create)
		wp_site_create "${@}"
		;;

	wp-site-domain)
		wp_site_domain "${@}"
		;;

	wp-safecss)
		wp_safecss "${@}"
		;;

	*)
		exit 1
esac
