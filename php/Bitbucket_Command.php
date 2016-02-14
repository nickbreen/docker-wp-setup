<?php
/**
 * Provides for installation of plugins and themes from Bitbucket.
 */
class Bitbucket_Command extends SCM_Command {

  static protected function tgz($args, $assoc_args) {
    @list( $repo, $tag ) = $args;
    $url = sprintf("https://bitbucket.org/%s/get/%s.tar.gz", $repo, $tag ?: 'master');
    if (array_intersect_key($assoc_args, array('key' => TRUE, 'secret' => TRUE))) {
      WP_CLI::debug("Fetching $url via OAuth");
      $tgz = self::fetch_tarball_via_oauth($assoc_args['key'], $assoc_args['secret'], $url);
    } else {
      WP_CLI::debug("Fetching $url via cURL");
      $tgz = self::fetch_tarball($url);
    }
    WP_CLI::debug("Fetched $tgz");
    WP_CLI::debug("Converting $tgz to zip");
    $zip = self::tgz_to_zip($repo, $tgz);
    WP_CLI::debug("Converted $tgz to $zip");
    return array($url, $tgz, $zip);
  }

  /**
   * Installs a plugin hosted at Bitbucket.
   *
   * ## OPTIONS
   *
   * <command>
   * : Only ```install``` is currently supported.
   *
   * <repository>
   * : The repository to install. In the form ```account/repository```.
   *
   * [<tag>]
   * : Optional release|tag|branch|commitish, defaults to the latest
   *   release, a tag, or master.
   *
   * [--key=<key>]
   * : OAuth1.0a key to authenticate access.
   *
   * [--secret=<secret>]
   * : OAuth1.0a secret to authenticate access.
   *
   * ## EXAMPLES
   *
   *     wp bitbucket plugin install CherryFramework/cherry-plugin v1.2.8.1
   *
   * @synopsis <command> <repository> [<tag>] [--key=<key>] [--secret=<secret>]
   */
  function plugin($args, $assoc_args) {
    self::apply('plugin', $args, $assoc_args);
  }

  /**
   * Installs a theme hosted at Bitbucket.
   *
   * ## OPTIONS
   *
   * <command>
   * : Only ```install``` is currently supported.
   *
   * <repository>
   * : The repository to install. In the form ```account/repository```.
   *
   * [<tag>]
   * : Optional release|tag|branch|commitish, defaults to the latest
   *   release, a tag, or master.
   *
   * [--key=<key>]
   * : Optional OAuth1.0a key to authenticate access.
   *
   * [--secret=<secret>]
   * : Optional OAuth1.0a secret to authenticate access.
   *
   * ## EXAMPLES
   *
   *     wp bitbucket plugin install CherryFramework/cherry-plugin v1.2.8.1
   *
   * @synopsis <command> <repository> [<tag>] [--key=<key>] [--secret=<secret>]
   */
  function theme( $args, $assoc_args ) {
    self::apply('theme', $args, $assoc_args);
  }

}

WP_CLI::add_command( 'bitbucket', 'Bitbucket_Command' );
