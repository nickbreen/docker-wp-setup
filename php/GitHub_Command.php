<?php
/**
 * Provides for installation of plugins and themes from GitHub.
 */
class GitHub_Command extends SCM_Command {

  static protected function tgz($args, $assoc_args) {
    @list( $repo, $tag ) = $args;
    // Get the tarball URL for the latest (or specified release)
    $url = sprintf("https://api.github.com/repos/%s/releases/%s", $repo, $tag ? "tags/${tag}" : 'latest');
    WP_CLI::debug("Querying for releases: $url");
    $url = self::tarball_url($url, @$assoc_args['token']);

    // If no releases are available fail-back to a commitish
    if ($url)
      WP_CLI::log("Found release: $url");
    else
      $url = sprintf("https://api.github.com/repos/%s/tarball/%s", $repo, $tag ?: 'master');

    WP_CLI::debug("Fetching $url");
    $tgz = self::fetch_tarball($url, @$assoc_args['token']);
    WP_CLI::debug("Fetched $tgz");

    WP_CLI::debug("Converting $tgz to zip");
    $zip = self::tgz_to_zip($repo, $tgz);
    WP_CLI::debug("Converted $tgz to $zip");

    return array($url, $tgz, $zip);
  }

  /**
   * Installs a plugin hosted at GitHub.
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
   * : Optional release|tag|branch|commitish, defaults to master.
   *
   * [--token=<token>]
   * : Optional GitHub token to authenticate access.
   *
   * ## EXAMPLES
   *
   *     wp github plugin install CherryFramework/cherry-plugin v1.2.8.1
   *
   * @synopsis <command> <repository> [<tag>] [--token=<token>]
   */
  function plugin($args, $assoc_args) {
    self::apply('plugin', $args, $assoc_args);
  }

  /**
   * Installs a plugin hosted at GitHub.
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
   * : Optional release|tag|branch|commitish, defaults to master.
   *
   * [--token=<token>]
   * : Optional GitHub token to authenticate access.
   *
   * ## EXAMPLES
   *
   *     wp github theme install CherryFramework/CherryFramework v3.1.5
   *
   * @synopsis <command> <repository> [<tag>] [--token=<token>]
   */
  function theme( $args, $assoc_args ) {
    self::apply('theme', $args, $assoc_args);
  }
}
