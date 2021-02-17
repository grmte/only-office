#!/bin/bash

docker network create --driver bridge onlyoffice


# Ref: https://github.com/ONLYOFFICE/Docker-CommunityServer/blob/4e33d29eae33f50fe724a54ce13142c8fe964b2d/README.md#installing-mysql
echo "[mysqld]
sql_mode = 'NO_ENGINE_SUBSTITUTION'
max_connections = 1000
max_allowed_packet = 1048576000
group_concat_max_len = 2048
log-error = /var/log/mysql/error.log" > /app/onlyoffice/mysql/conf.d/onlyoffice.cnf

echo "CREATE USER 'onlyoffice_user'@'localhost' IDENTIFIED BY 'onlyoffice_pass';
CREATE USER 'mail_admin'@'localhost' IDENTIFIED BY 'Isadmin123';
GRANT ALL PRIVILEGES ON * . * TO 'root'@'%' IDENTIFIED BY 'my-secret-pw';
GRANT ALL PRIVILEGES ON * . * TO 'onlyoffice_user'@'%' IDENTIFIED BY 'onlyoffice_pass';
GRANT ALL PRIVILEGES ON * . * TO 'mail_admin'@'%' IDENTIFIED BY 'Isadmin123';
FLUSH PRIVILEGES;" > /app/onlyoffice/mysql/initdb/setup.sql



# Ref:https://github.com/ONLYOFFICE/Docker-CommunityServer/blob/4e33d29eae33f50fe724a54ce13142c8fe964b2d/README.md#installing-mysql
sudo docker run --net onlyoffice -i -t -d --restart=always --name onlyoffice-mysql-server \
 -v /app/onlyoffice/mysql/conf.d:/etc/mysql/conf.d \
 -v /app/onlyoffice/mysql/data:/var/lib/mysql \
 -v /app/onlyoffice/mysql/initdb:/docker-entrypoint-initdb.d \
 -e MYSQL_ROOT_PASSWORD=my-secret-pw \
 -e MYSQL_DATABASE=onlyoffice \
 mysql:5.7


# Ref: https://hub.docker.com/r/onlyoffice/documentserver/
docker run --net onlyoffice -i -t -d --restart=always --name onlyoffice-document-server \
    -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data \
    -v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice \
    onlyoffice/documentserver

docker run --net onlyoffice --privileged -i -t -d --restart=always --name onlyoffice-mail-server \
    -p 25:25 -p 143:143 -p 587:587 \
    -v /app/onlyoffice/MailServer/data:/var/vmail \
    -v /app/onlyoffice/MailServer/data/certs:/etc/pki/tls/mailserver \
    -v /app/onlyoffice/MailServer/logs:/var/log \
    -v /app/onlyoffice/MailServer/mysql:/var/lib/mysql \
    -h yourdomain.com \
    onlyoffice/mailserver

# Ref: https://github.com/ONLYOFFICE/Docker-CommunityServer/blob/4e33d29eae33f50fe724a54ce13142c8fe964b2d/README.md#installing-mysql
docker run --net onlyoffice -i -t -d --restart=always --name onlyoffice-community-server \
    -p 80:80 -p 5222:5222 -p 443:443 \
    -v /app/onlyoffice/CommunityServer/data:/var/www/onlyoffice/Data \
    -v /app/onlyoffice/CommunityServer/logs:/var/log/onlyoffice \
    -v /app/onlyoffice/CommunityServer/letsencrypt:/etc/letsencrypt \
    -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/DocumentServerData \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -e MYSQL_SERVER_ROOT_PASSWORD=my-secret-pw \
    -e MYSQL_SERVER_DB_NAME=onlyoffice \
    -e MYSQL_SERVER_HOST=onlyoffice-mysql-server \
    -e MYSQL_SERVER_USER=onlyoffice_user \
    -e MYSQL_SERVER_PASS=onlyoffice_pass \
    -e DOCUMENT_SERVER_PORT_80_TCP_ADDR=onlyoffice-document-server \
    -e MAIL_SERVER_DB_HOST=onlyoffice-mail-server \
    onlyoffice/communityserver
