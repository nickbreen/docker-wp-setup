#!/bin/bash

set -e -x -o pipefail

chown wp:www-data /var/www

setuser wp wp config create --force
setuser wp wp core verify-checksums || setuser wp wp core download --force

while ! setuser wp wp db query "SELECT VERSION();"
do
    sleep 5
done
setuser wp wp core install

ls -lrt /var/www

curl -fsSI www && echo "Hooray Apache is working!"
curl -fsSI www/phpinfo.php && echo "Hooray PHP-FPM is working!"
