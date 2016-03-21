<?php
require_once 'SCM_Command.php';
require_once 'GitHub_Command.php';
require_once 'Bitbucket_Command.php';

WP_CLI::add_command( 'github', 'GitHub_Command' );
WP_CLI::add_command( 'bitbucket', 'Bitbucket_Command' );
