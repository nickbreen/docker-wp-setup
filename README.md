Automated set up utilities for [WordPress].

WordPress is set up with a non-root user.

Volumes for the docroot and wp-content/uploads directories are configured.

# Usage

To automatically setup WP use two containers:

    # docker-compose.yml
    setup:
      image: nickbreen/wp-setup
      environment:
        # yadda, see below

The installation is hardcoded to `/var/www`.

# Configuration

The database configuration can be specified explicitly with:

- `WP_DB_HOST`
- `WP_DB_PORT`
- `WP_DB_NAME`
- `WP_DB_USER`
- `WP_DB_PASSWORD`
- `WP_DB_PREFIX`

If any are omitted then values are inferred from the linked ```:mysql```
container, otherwise sensible defaults are used.

Variable             | Value inferred from            | Default
-------------------- | ------------------------------ | ---------
`WP_DB_NAME`         | `MYSQL_ENV_MYSQL_DATABASE`     | wordpress
`WP_DB_USER`         | `MYSQL_ENV_MYSQL_USER`         | wordpress
`WP_DB_PASSWORD`     | `MYSQL_ENV_MYSQL_PASSWORD`     | wordpress
`WP_DB_HOST`         | `MYSQL_PORT_3306_TCP_ADDR`     | mysql
`WP_DB_PORT`         | `MYSQL_PORT_3306_TCP_PORT`     | 3306
`WP_DB_PREFIX`       | N/A                            | wp_

`--extra-php` is supported with the `WP_EXTRA_PHP` environment variable. E.g.

    WP_EXTRA_PHP: |
      define('DISABLE_WP_CRON', true);

## Installation

The initial DB is installed, if not already installed in the DB, using the
following variables; the setup script will complain if any are unset.

- `WP_LOCALE` (default `en_NZ`)
- `WP_URL`
- `WP_TITLE`
- `WP_ADMIN_USER`
- `WP_ADMIN_PASSWORD`
- `WP_ADMIN_EMAIL`

## Arbitrary WP-CLI Commands

Any arbitrary WP-CLI commands can be executed, actually any commands as the
value is processed by `sh`. Any environment variable prefixed with `WP_COMMANDS`
will be processed.

    WP_COMMANDS_0: |
      wp plugin activate --network jetpack
    WP_COMMANDS_1: |
      wp site create --slug=site1 --title="Site 1"
      wp --url=http://site1.example.com rewrite structure /%postname%
      wp --url=http://site1.example.com rewrite flush
    WP_COMMANDS_2: |
      wp site create --slug=site2 --title="Site 2"
      wp --url=http://site2.example.com rewrite structure /%postname%
      wp --url=http://site2.example.com rewrite flush
    WP_COMMANDS_3: |
      wp site create --slug=site3 --title="Site 3"
      wp --url=http://site3.example.com rewrite structure /%postname%
      wp --url=http://site3.example.com rewrite flush

## Themes and Plugins

Themes and plugins can be installed from the WordPress.org repository, from a
URL to the theme's or plugin's ZIP file using `WP_COMMANDS`; e.g.:

    WP_COMMANDS: |
      wp theme install theme-slug --version=1.2.3
      wp theme install http://example.com/theme.zip --activate
      wp plugin install plugin-slug --version=1.2.3
      wp plugin install https://example.com/plugin.zip

Themes and plugins can also be installed from [Bitbucket] (OAuth 1.0a supported
for private repositories) and [GitHub] (HTTP Basic Auth using personal access
tokens for private repositories); e.g.:

  WP_COMMANDS: |
    wp github theme install CherryFramework/CherryFramework v3.1.5
    wp github theme install CherryFramework/CherryFramework v3.1.5 --token=XXXXX
    wp bitbucket plugin install CherryFramework/cherry-plugin v3.1.5
    wp bitbucket plugin install CherryFramework/cherry-plugin v3.1.5 --key=XXXX --secret=XXXXXX

For both GitHub and Bitbucket the version/release tag is optional and defaults
to the `latest` release, or if no releases exist, to `master`.

[Bitbucket]: https://bitbucket.com
[GitHub]: https://github.com
[WordPress]: https://wordpress.org
