Automated set up utilities for [WordPress].

WordPress is set up with a non-root user.

Volumes for the docroot and wp-content/uploads directories are configured.

The installation is hardcoded to `/var/www`.

# Usage

See `docker-compose.yml` for a usage example.

`attach` or `exec` (etc) into the container and execute `setup`.

    docker exec -itu wp CONTAINER bash -l -c 'setup'

This image provides and uses [WP-CLI].

## Download

The version and a locale can be specified with environment variables.

| Variable   | Example | Default
|------------|---------|---------
| WP_VERSION | 4.4.2   | Latest
| WP_LOCALE  | en_NZ   | en_US

## Configuration

The database configuration can be specified explicitly with environment variables.

If any are omitted then values are inferred from the linked ```:mysql```
container, otherwise sensible defaults are used.

| Variable            | Value inferred from           | Default
|---------------------|-------------------------------|---------
| WP_DB_NAME          | MYSQL_ENV_MYSQL_DATABASE      |
| WP_DB_USER          | MYSQL_ENV_MYSQL_USER          |
| WP_DB_PASSWORD      | MYSQL_ENV_MYSQL_PASSWORD      |
| WP_DB_HOST          | MYSQL_PORT_3306_TCP_ADDR      | mysql
| WP_DB_PORT          | MYSQL_PORT_3306_TCP_PORT      | 3306
| WP_DB_PREFIX        | N/A                           |
| WP_DB_ROOT_USER     | N/A                           | root
| WP_DB_ROOT_PASSWORD | MYSQL_ENV_MYSQL_ROOT_PASSWORD |

The DB root user will be used to create the WP DB and user if they do not already exist.

`--extra-php` is supported with the `WP_EXTRA_PHP` environment variable. E.g.

    WP_EXTRA_PHP: |
      define('DISABLE_WP_CRON', true);

## Installation

The initial DB is installed, if not already installed in the DB, using the
following variables; the setup script will complain if any are unset.

| Variable          | Example             | Default
|-------------------|---------------------|---------
| WP_LOCALE         | en_NZ               | en_US
| WP_URL            | http://example.com  |
| WP_TITLE          | Example Title       |
| WP_ADMIN_EMAIL    | admin@example.com   |
| WP_ADMIN_USER     | admin               |
| WP_ADMIN_PASSWORD |                     |

## Multisite

Multisite is supported, it is enabled when the `WP_SUBDOMAINS` environment
variable is set.

| Variable      | Example
|---------------|---------
| WP_SUBDOMAINS | "yes"  

Path-based multisite setups are not supported.

A domain mapping plugin is not required, though there is no UI to conveniently administer site domains.

Use the convenience function to register a new site. It will configure all domain mapping values.

    WP_COMMANDS: |
      new_site sitea sitea.dev http://sitea.dev "Site A"
      wp --url=http://sitea.dev theme activate twentyfourteen

Cookies are configured to be issued for only the site's domain. Cookies are shared between www.example.com and example.com.

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
      wp github theme install CherryFramework/CherryFramework v3.1.5 --token=XXX
      wp bitbucket plugin install CherryFramework/cherry-plugin v3.1.5
      wp bitbucket plugin install CherryFramework/cherry-plugin v3.1.5 --key=XXX --secret=XXX

For both GitHub and Bitbucket the version/release tag is optional and defaults
to the `latest` release, or if no releases exist, to `master`.

## Arbitrary Commands

Any arbitrary commands can be executed, actually any commands as the
value is processed by `sh`. Any environment variable prefixed with `WP_COMMANDS`
will be processed.

    WP_COMMANDS_0: | # Install plugins
      wp plugin install jetpack --activate
    WP_COMMANDS_1: | # Configure themes
      wp theme activate twentyfourteen
    WP_COMMANDS_2: | # Set some options
      wp rewrite structure /%postname%
      wp rewrite flush

[WP-CLI]: http://wp-cli.org
[Bitbucket]: https://bitbucket.com
[GitHub]: https://github.com
[WordPress]: https://wordpress.org
