<?php
/**
 * Implements example command.
 */
class SCM_Command extends WP_CLI_Command {

    /**
     * Prints a greeting.
     *
     * ## OPTIONS
     *
     * <name>
     * : The name of the person to greet.
     *
     * ## EXAMPLES
     *
     *     wp example hello Newman
     *
     * @synopsis <name>
     */
    function hello( $args, $assoc_args ) {
        list( $name ) = $args;

        // Print a success message
        WP_CLI::success( "Hello, $name!" );
    }

    /**
     * Installs a plugin or theme from a tarball.
     */
    static protected function tgz_to_zip($repo, $tgz) {
      // TODO pure PHP
      $zip = shell_exec("set - - $repo $tgz" . PHP_EOL . <<<'EOS'
TMP=$(mktemp -d)
mkdir -p $TMP/${2##*/}
tar xzf $3 --strip-components 1 -C $TMP/${2##*/}
( cd $TMP; zip -0qrm ${2##*/}.zip ${2##*/} )
echo -n $TMP/${2##*/}.zip
EOS
      );
      return $zip;
    }

    static protected function tarball_url($url, $auth = NULL) {
      if ($auth)
        $auth = "-u ${auth}";
      // TODO pure PHP
      return trim(shell_exec("curl -sSfL ${auth} ${url} | jq -r '.tarball_url'"));
    }

    static protected function fetch_tarball($url, $auth = NULL) {
      if ($auth)
        $auth = "-u ${auth}";
      // TODO pure PHP
      return shell_exec("echo -n $(readlink -n -f .)/; curl -sSfLJO -w '%{filename_effective}' ${auth} ${url}");
    }

}

/**
 * Provides for installation of plugins and themes from GitHub.
 */
class GitHub_Command extends SCM_Command {

  static protected function tgz($args, $assoc_args) {
    list( $repo, $tag ) = $args;
    // Get the tarball URL for the latest (or specified release)
    $url = sprintf("https://api.github.com/repos/%s/releases/%s", $repo, $tag ? "tags/${tag}" : 'latest');
    WP_CLI::log("Querying for releases: $url");
    $url = self::tarball_url($url, @$assoc_args['token']);

    // If no releases are available fail-back to a commitish
    if ($url)
      WP_CLI::log("Found release: $url");
    else
      $url = sprintf("https://api.github.com/repos/%s/tarball/%s", $repo, $tag ?: 'master');

    WP_CLI::log("Fetching $url");
    $tgz = self::fetch_tarball($url, @$assoc_args['token']);
    WP_CLI::log("Fetched $tgz");

    WP_CLI::log("Converting $tgz to zip");
    $zip = self::tgz_to_zip($repo, $tgz);
    WP_CLI::log("Converted $tgz to $zip");

    return array($url, $tgz, $zip);
  }

  static protected function apply($cmd, $args, $assoc_args) {
    $op = array_shift($args);
    list($url, $tgz, $zip) = self::tgz($args, $assoc_args);
    WP_CLI::log("Installing from $zip");
    WP_CLI::run_command(array($cmd, $op, $zip), array('force' => 1));
    WP_CLI::log("Removing $tgz, $zip");
    unlink($tgz);
    unlink($zip);
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

WP_CLI::add_command( 'github', 'GitHub_Command' );
