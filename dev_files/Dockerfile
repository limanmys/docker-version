# LIMAN DOCKERFILE <DEV VERSION>
# AUTHOR: Doğukan Öksüz <dogukan@liman.dev>

FROM ubuntu:jammy
EXPOSE 80 443

# DEPENDENCIES
RUN echo LIMAN.HAVELSAN.COM.TR
RUN export DEBIAN_FRONTEND=noninteractive;
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Istanbul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt -yqq update
RUN DEBIAN_FRONTEND=noninteractive apt -yqq install software-properties-common gnupg2 ca-certificates
RUN add-apt-repository --yes ppa:ondrej/php

# LIMAN DEPS
RUN DEBIAN_FRONTEND=noninteractive apt -yqq install sudo wget curl gpg zip unzip nginx sysstat php8.1-redis php8.1-fpm php8.1-gd php8.1-curl php8.1 php8.1-sqlite3 php8.1-snmp php8.1-mbstring php8.1-xml php8.1-zip php8.1-posix libnginx-mod-http-headers-more-filter libssl3 supervisor php8.1-pgsql pgloader php8.1-bcmath rsync dnsutils php8.1-ldap php8.1-smbclient krb5-user php8.1-ssh2 smbclient novnc

# FILES
RUN bash -c 'mkdir -p /liman_files/{server,certs,logs,database,sandbox,keys,extensions,modules,packages}'

# CORE
COPY core /liman_files/server

# PHP SANDBOX
RUN mkdir -p /liman_files/sandbox
COPY php-sandbox /liman_files/sandbox/php

# USERS
RUN groupadd -g 2800 liman
RUN useradd liman -u 2801 -g 2800 -m
RUN useradd extuser -u 2802 -g 2800 -m

# PERMS
RUN cp -f /liman_files/server/storage/limanctl /usr/bin/limanctl

# VNC SETTINGS
RUN rm -rf /liman_files/keys/vnc
RUN mkdir /liman_files/keys/vnc
RUN chmod 700 /liman_files/keys/vnc
RUN touch /liman_files/keys/vnc/config
RUN chown liman:liman /liman_files/keys/vnc /liman_files/keys/vnc/config
RUN chmod 700 /liman_files/keys/vnc/config

# SETTINGS
RUN sed -i "s/www-data/liman/g" /etc/php/8.1/fpm/pool.d/www.conf
RUN sed -i "s/www-data/liman/g" /etc/nginx/nginx.conf
RUN mv /liman_files/server/storage/nginx.conf /etc/nginx/sites-available/liman.conf
RUN ln -s /etc/nginx/sites-available/liman.conf /etc/nginx/sites-enabled/liman.conf
COPY config/nginx_default /etc/nginx/sites-available/default 

# SERVICES
RUN mkdir /run/php
COPY config/supervisor.conf /etc/supervisor/supervisor.conf
COPY config/supervisor /etc/supervisor/conf.d

# START LIMAN
COPY init.sh /tmp/init.sh
RUN ["chmod", "755", "/tmp/init.sh"]
RUN ["chmod", "+x", "/tmp/init.sh"]

# FREE UP SPACE
RUN apt clean -yqq
RUN apt autoclean -yqq

ENTRYPOINT ["/tmp/init.sh"]