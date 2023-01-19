# LIMAN DOCKERFILE
# AUTHOR: Doğukan Öksüz <dogukan@liman.dev>

FROM ubuntu:jammy
EXPOSE 80 443

# DEPENDENCIES
RUN export DEBIAN_FRONTEND=noninteractive;
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND noninteractive
# RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
ENV TZ=Europe/Istanbul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt -yqq update
RUN DEBIAN_FRONTEND=noninteractive apt -yqq install software-properties-common gnupg2 ca-certificates
RUN add-apt-repository --yes ppa:ondrej/php

# LIMAN DEPS
RUN DEBIAN_FRONTEND=noninteractive apt -yqq install sudo wget curl gpg zip unzip nginx redis php8.1-redis php8.1-fpm php8.1-gd php8.1-curl php8.1 php8.1-sqlite3 php8.1-snmp php8.1-mbstring php8.1-xml php8.1-zip php8.1-posix libnginx-mod-http-headers-more-filter libssl3 supervisor php8.1-pgsql pgloader php8.1-bcmath rsync dnsutils php8.1-ldap php8.1-smbclient krb5-user php8.1-ssh2 smbclient novnc python3.10 python3-paramiko python3-tornado

# CORE
RUN wget "https://github.com/limanmys/core/archive/refs/heads/master.zip" -O "core.zip"
RUN unzip -qq core.zip
RUN mkdir -p /liman/server
RUN mv core-master/* /liman/server
RUN mv core-master/.env.example /liman/server
RUN rm -rf core.zip

# PHP SANDBOX
RUN wget "https://github.com/limanmys/php-sandbox/archive/refs/heads/master.zip" -O "sandbox.zip"
RUN unzip -qq sandbox.zip
RUN mkdir -p /liman/sandbox/php
RUN mv php-sandbox-master/* /liman/sandbox/php/
RUN rm -rf sandbox.zip php-sandbox-master

# EXT TEMPLATES
RUN wget "https://github.com/limanmys/extension_templates/archive/master.zip" -O "extension_templates.zip"
RUN unzip -qq extension_templates.zip
RUN mkdir -p /liman/server/storage/extension_templates
RUN mv extension_templates-master/* /liman/server/storage/extension_templates
RUN rm -rf extension_templates.zip extension_templates-master

# WEBSSH
RUN wget "https://github.com/limanmys/webssh/archive/master.zip" -O "webssh.zip"
RUN unzip -qq webssh.zip
RUN mkdir -p /liman/webssh
RUN mv webssh-master/* /liman/webssh
RUN rm -rf webssh.zip webssh-master

# RENDER ENGINE
RUN curl -s https://api.github.com/repos/limanmys/fiber-render-engine/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | wget -qi -
RUN unzip liman_render*.zip
RUN mv liman_render /liman/server/storage/liman_render

# COMPOSER
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

RUN composer install --no-dev --no-scripts -d /liman/server
RUN composer install --no-dev -d /liman/sandbox/php

# FILES
RUN bash -c 'mkdir -p /liman/{server,certs,logs,database,sandbox,keys,extensions,modules,packages}'
RUN ls -la '/liman/server'
RUN cp '/liman/server/.env.example' '/liman/server/.env'

# USERS
RUN groupadd -g 2800 liman
RUN useradd liman -u 2801 -g 2800 -m

# NEEDS
RUN rm -rf /liman/server/bootstrap/cache/*
RUN composer dump-autoload --optimize --no-dev -d /liman/server/
RUN php /liman/server/artisan package:discover
RUN php /liman/server/artisan key:generate

# CERT CREATION
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=TR/ST=Ankara/L=Merkez/O=Havelsan/CN=liman" -keyout /liman/certs/liman.key -out /liman/certs/liman.crt

# SETTINGS
RUN sed -i "s/www-data/liman/g" /etc/php/8.1/fpm/pool.d/www.conf
RUN sed -i "s/www-data/liman/g" /etc/nginx/nginx.conf
RUN mv /liman/server/storage/nginx.conf /etc/nginx/sites-available/liman.conf
RUN ln -s /etc/nginx/sites-available/liman.conf /etc/nginx/sites-enabled/liman.conf
RUN printf "#LIMAN_SECURITY_OPTIMIZATIONS \n server {\n    listen 80 default_server;\n    listen [::]:80 default_server;\n    server_name _;\n     server_tokens off;\n     more_set_headers 'Server: LIMAN MYS';\n     return 301 https://\\\$host\\\$request_uri;\n } " >  /etc/nginx/sites-available/default 
RUN cat /etc/nginx/sites-available/default

# SERVICES
RUN printf "[supervisord] \n nodaemon=true \n \n[include] \n files = /etc/supervisor/conf.d/*.conf\n" > /etc/supervisor/supervisor.conf
RUN printf "\n[program:limanrender]\ncommand=/liman/server/storage/liman_render \n autostart=true \n autorestart=true \n stderr_logfile=/liman/logs/limanrender.err.log \n stdout_logfile=/liman/logs/limanrender.out.log \n \n" >> /etc/supervisor/supervisor.conf
RUN printf "[program:limansystem]\ncommand=/liman/server/storage/liman_system \n autostart=true \n autorestart=true \n stderr_logfile=/liman/logs/limansystem.err.log \n stdout_logfile=/liman/logs/limansystem.out.log \n \n" >> /etc/supervisor/supervisor.conf
RUN printf "[program:limansocket]\ncommand=/usr/bin/php /liman/server/artisan websockets:serve --host=127.0.0.1 \n numprocs=2 \n autostart=true \n autorestart=true \n user=liman \n stderr_logfile=/liman/logs/limansocket.err.log \n stdout_logfile=/liman/logs/limansocket.out.log \n \n" >> /etc/supervisor/supervisor.conf
RUN chmod +x /liman/server/storage/liman_render
RUN chmod +x /liman/server/storage/liman_system
RUN chmod +x /liman/server/storage/limanctl
RUN cp -f /liman/server/storage/limanctl /usr/bin/limanctl
RUN mkdir /run/php
RUN printf "[program:php-fpm]\n command=/usr/sbin/php-fpm8.1 --nodaemonize --fpm-config /etc/php/8.1/fpm/php-fpm.conf \n autostart=true \n autorestart=true \n stderr_logfile=/liman/logs/phpfpm.err.log \n stdout_logfile=/liman/logs/phpfpm.out.log \n \n" >> /etc/supervisor/supervisor.conf
RUN printf "[program:nginx]\n command=nginx -g \"daemon off;\" \n stdout_logfile=/dev/stdout \n stdout_logfile_maxbytes=0 \n stderr_logfile=/dev/stderr\n stderr_logfile_maxbytes=0\n\n" >> /etc/supervisor/supervisor.conf
RUN chown -R liman:liman /liman
RUN printf "[program:limansocket]\n command=/usr/bin/php /liman/server/artisan websockets:serve --host=127.0.0.1 \n autostart=true \n autorestart=true \n stderr_logfile=/liman/logs/phpsoc.err.log \n stdout_logfile=/liman/logs/phpsoc.out.log \n \n" >> /etc/supervisor/supervisor.conf
RUN printf "[program:webssh]\n command=/usr/bin/python3 /liman/webssh/run.py \n autostart=true \n autorestart=true \n stderr_logfile=/liman/logs/webssh.err.log \n stdout_logfile=/liman/logs/webssh.out.log \n \n" >> /etc/supervisor/supervisor.conf
RUN printf "[program:novnc]\n command=/usr/bin/websockify --web=/usr/share/novnc 6080 --cert=/liman/certs/liman.crt --key=/liman/certs/liman.key --token-plugin TokenFile --token-source /liman/keys/vnc/config \n autostart=true \n autorestart=true \n stderr_logfile=/liman/logs/novnc.err.log \n stdout_logfile=/liman/logs/novnc.out.log \n \n" >> /etc/supervisor/supervisor.conf

# VNC SETTINGS
RUN rm -rf /liman/keys/vnc
RUN mkdir /liman/keys/vnc
RUN chmod 700 /liman/keys/vnc
RUN touch /liman/keys/vnc/config
RUN chown liman:liman /liman/keys/vnc /liman/keys/vnc/config
RUN chmod 700 /liman/keys/vnc/config

# START LIMAN
COPY init.sh /tmp/init.sh
RUN ["chmod", "755", "/tmp/init.sh"]
RUN ["chmod", "+x", "/tmp/init.sh"]

ENTRYPOINT ["/tmp/init.sh"]