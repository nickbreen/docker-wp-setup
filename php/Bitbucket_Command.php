<?php
/**
 * Provides for installation of plugins and themes from Bitbucket.
 */
class Bitbucket_Command extends SCM_Command {

  static protected function tgz($args, $assoc_args) {
    list( $repo, $tag ) = $args;
    $url = sprintf("https://bitbucket.org/%s/get/%s.tar.gz", $repo, $tag ?: 'master');
    if (array_intersect_key($assoc_args, array('key' => TRUE, 'secret' => TRUE))) {
      WP_CLI::log("Fetching $url via OAuth");
      $tgz = self::fetch_tarball_via_oauth($assoc_args['key'], $assoc_args['secret'], $url);
    } else {
      WP_CLI::log("Fetching $url via cURL");
      $tgz = self::fetch_tarball($url);
    }
    WP_CLI::log("Fetched $tgz");
    WP_CLI::log("Converting $tgz to zip");
    $zip = self::tgz_to_zip($repo, $tgz);
    WP_CLI::log("Converted $tgz to $zip");
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

if (!function_exists('http_parse_headers')) {
  function http_parse_headers($header) {
      $retVal = array();
      $fields = explode("\r\n", preg_replace('/\x0D\x0A[\x09\x20]+/', ' ', $header));
      foreach( $fields as $field ) {
          if( preg_match('/([^:]+): (.+)/m', $field, $match) ) {
              $match[1] = preg_replace_callback('/(?<=^|[\x09\x20\x2D])./', function ($x) { return strtoupper($x[0]); }, strtolower(trim($match[1])));
              if( isset($retVal[$match[1]]) ) {
                  if ( is_array( $retVal[$match[1]] ) ) {
                      $i = count($retVal[$match[1]]);
                      $retVal[$match[1]][$i] = $match[2];
                  }
                  else {
                      $retVal[$match[1]] = array($retVal[$match[1]], $match[2]);
                  }
              } else {
                  $retVal[$match[1]] = trim($match[2]);
              }
          }
      }
      return $retVal;
  }
}
