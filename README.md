Automated set up utilities for WordPress.

WordPress is set up with a non-root user.

Volumes for the docroot and wp-content/uploads directories are configured.

# Usage

To automatically setup WP use two containers:

    # docker-compose.yml
    wp-setup:
      image: nickbreen/wp-setup
      environment:
        # yadda, see below

# Configuration

The database configuration can be specified explicitly with:

- ```WP_DB_HOST```
- ```WP_DB_PORT```
- ```WP_DB_NAME```
- ```WP_DB_USER```
- ```WP_DB_PASSWORD```
- ```WP_DB_PREFIX```

If any are omitted then values are inferred from the linked ```:mysql``` container, otherwise sensible defaults are used.

Variable             | Value inferred from            | Default
-------------------- | ------------------------------ | ---------
```WP_DB_NAME```     | ```MYSQL_ENV_MYSQL_DATABASE``` | wordpress
```WP_DB_USER```     | ```MYSQL_ENV_MYSQL_USER```     | wordpress
```WP_DB_PASSWORD``` | ```MYSQL_ENV_MYSQL_PASSWORD``` | wordpress
```WP_DB_HOST```     | ```MYSQL_PORT_3306_TCP_ADDR``` | mysql
```WP_DB_PORT```     | ```MYSQL_PORT_3306_TCP_PORT``` | 3306
```WP_DB_PREFIX```   | N/A                            | wp_

```--extra-php``` is supported with the ```WP_EXTRA_PHP``` environment variable. E.g.

    WP_EXTRA_PHP: |
      define('DISABLE_WP_CRON', true);

## Installation

The initial DB is installed, if not already installed in the DB, using the variables; each has a useless default value, so make sure you set them:
- ```WP_LOCALE``` (default ```en_NZ```)
- ```WP_URL```
- ```WP_TITLE```
- ```WP_ADMIN_USER```
- ```WP_ADMIN_PASSWORD```
- ```WP_ADMIN_EMAIL```

## Themes and Plugins

Themes and plugins can be installed from the WordPress.org repository, from a URL to the theme's or plugin's ZIP file. I.e.:

Each theme or plugin is on its own line.

    WP_THEMES: |
      theme-slug
      http://theme.domain/theme-url.zip

    WP_PLUGINS: |
      plugin-slug
      https://plugin.domain/plugin-url.zip

Themes and plugins can also be installed from [Bitbucket] (OAuth 1.0a supported for private repositories) and [GitHub] (HTTP Basic Auth using personal access tokens for private repositories):

      BB_KEY: "BitBucket API OAuth Key"
      BB_SECRET: "BitBucket API OAuth Secret"
      BB_PLUGINS: |
        account/repo [tag]
      BB_THEMES: |
        account/repo [tag]
      GH_TOKEN: username:token
      GH_THEME: |
        CherryFramework/CherryFramework

[Bitbucket]: https://bitbucket.com "Bitbucket"
[GitHub]: https://github.com "GitHub"

## Options

Any WordPress options can be set as JSON using ```WP_OPTIONS```. E.g.

    WP_OPTIONS: |
      timezone_string "Pacific/Auckland"
      some_complex_option {"access_key_id":"...","secret_access_key":"..."}

Simple strings must be quoted.

To set non-JSON options, use ```WP_COMMANDS```.

## Arbitrary WP-CLI Commands

Any WP-CLI command can be executed; e.g.:

    WP_COMMANDS: |
      rewrite structure /%postname%
      rewrite flush
