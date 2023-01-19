#!/usr/bin/env sh

touch /liman/logs/liman.log
touch /liman/logs/liman_new.log
chown -R liman:liman /liman/logs

sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/g" /liman/server/.env 
sed -i "s/^DB_HOST=127.0.0.1/DB_HOST=liman-db/g" /liman/server/.env 

php /liman/server/artisan migrate --force 
php /liman/server/artisan cache:clear 
php /liman/server/artisan view:clear 
php /liman/server/artisan config:clear

redis-server --daemonize yes
/usr/bin/supervisord -c /etc/supervisor/supervisor.conf 
