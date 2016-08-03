<?php
/**
 * Implements example command.
 */
abstract class SCM_Command extends WP_CLI_Command
{
    const TGZ_TO_ZIP = <<<'EOS'
TMP=$(mktemp -d)
mkdir -p "$TMP/${2##*/}"
tar xzf $3 --strip-components 1 -C "$TMP/${2##*/}"
( cd $TMP; zip -0qrm "${2##*/}.zip" "${2##*/}" )
echo -n "$TMP/${2##*/}.zip"
EOS;

    const RE = <<<'ERE'
/
(?P<media>[^\/]+)
\/
(?:(?P<tree>.+)\.)?
(?P<subtype>[^;+]+)
(?:\+(?P<suffix>[^;]+))?
(?P<parameters_scalar>
(?: #P<parameter>
  ;[ ]
  (?: #P<pname>
    [^=]+)
  (?:=(?: #P<pvalue>
    [^;]*))?
)*
)
/x
ERE;

    const PRE = <<<'ERE'
/
;[ ]
(?P<pname>[^=]+)
(?:=(?P<pvalue>[^;]*))?
/x
ERE;

    /**
    * Installs a plugin or theme from a tarball.
    */
    protected static function tgz_to_zip($repo, $tgz)
    {
        // TODO pure PHP
        $zip = shell_exec("set - - $repo $tgz".PHP_EOL.self::TGZ_TO_ZIP);
        return $zip;
    }

    protected static function tarball_url($url, $auth = null)
    {
        if ($auth) {
            $auth = "-u ${auth}";
        }
    // TODO pure PHP
    return trim(shell_exec("curl -sfL ${auth} ${url} | jq -r '.tarball_url'"));
    }

    protected static function fetch_tarball($url, $auth = null)
    {
        if ($auth) {
            $auth = "-u ${auth}";
        }
    // TODO pure PHP
    return shell_exec("echo -n $(readlink -n -f .)/; curl -sfLJO -w '%{filename_effective}' ${auth} ${url}");
    }

    protected static function fetch_tarball_via_oauth($key, $secret, $uri)
    {
        try {
            $oauth = new OAuth($key, $secret);
            $oauth->fetch($uri);

            WP_CLI::debug($oauth->getLastResponseHeaders());

            $headers = http_parse_headers($oauth->getLastResponseHeaders());

            $mime_type = self::parse_content_type_header($headers['Content-Type']);

            $content_disposition = self::parse_content_disposition_header($headers['Content-Disposition']);

            $filename = empty($content_disposition['filename']) ?
                $filename = tmpfile() :
                sys_get_temp_dir().DIRECTORY_SEPARATOR.$content_disposition['filename'];

            file_put_contents($filename, $oauth->getLastResponse());

            return $filename;
        } catch (OAuthException $e) {
            WP_CLI::error_multi_line($e->getMessage(), true);
        }
        WP_CLI::error('Unknown error', true);
    }

    protected static function parse_content_disposition_header($header)
    {
        preg_match_all(self::PRE, $header, $x, PREG_SET_ORDER);
        foreach ($x as $p) {
            $content_disposition[$p['pname']] = $p['pvalue'];
        }

        return $content_disposition;
    }

    protected static function parse_content_type_header($header)
    {
        $mime_type = (object) [];
        preg_match(self::RE, $header, $m);
        foreach ($m as $i => $v) {
            if (is_string($i)) {
                $mime_type->$i = $v;
            }
        }

        preg_match_all(self::PRE, $mime_type->parameters_scalar, $ps, PREG_SET_ORDER);
        foreach ($ps as $x => $p) {
            $mime_type->parameters[$p['pname']] = $p['pvalue'];
        }

        return $mime_type;
    }

    abstract protected static function tgz($args, $assoc_args);

    protected static function apply($cmd, $args, $assoc_args)
    {
        $op = array_shift($args);
        list($url, $tgz, $zip) = static::tgz($args, $assoc_args);
        WP_CLI::debug("Installing from $zip");
        WP_CLI::run_command(array($cmd, $op, $zip), array('force' => 1));
        WP_CLI::debug("Removing $tgz, $zip");
        unlink($tgz);
        unlink($zip);
    }
}

if (!function_exists('http_parse_headers')) {
    function http_parse_headers($headers_raw)
    {
        $headers = array();
        $fields = explode("\r\n", preg_replace('/\x0D\x0A[\x09\x20]+/', ' ', $headers_raw));
        foreach ($fields as $field) {
            if (preg_match('/([^:]+): (.+)/m', $field, $match)) {
                $match[1] = preg_replace_callback('/(?<=^|[\x09\x20\x2D])./', function ($x) {
                    return strtoupper($x[0]);
                }, strtolower(trim($match[1])));
                if (isset($headers[$match[1]])) {
                    if (is_array($headers[$match[1]])) {
                        $i = count($headers[$match[1]]);
                        $headers[$match[1]][$i] = $match[2];
                    } else {
                        $headers[$match[1]] = array($headers[$match[1]], $match[2]);
                    }
                } else {
                    $headers[$match[1]] = trim($match[2]);
                }
            }
        }

        return $headers;
    }
}
