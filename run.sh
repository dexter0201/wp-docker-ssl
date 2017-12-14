#!/bin/bash

INSTALL_DIR=$PWD
COMPANION_INSTALLLED=1
WORDPRESS_IMAGE="wordpress:latest"
DB_IMAGE="mariadb:latest"

#
# Network name
# 
# Your container app must use a network conencted to your webproxy 
# https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion
#
NETWORK="webproxy"

# Path to store your database
DB_PATH="/path/to/your/local/database/folder"

# Root password for your database
MYSQL_ROOT_PASSWORD="mysqlrootpassword"

# Database name, user and password for your wordpress
MYSQL_DATABASE="mysqldatabase"
MYSQL_USER="mysqluser"
MYSQL_PASSWORD="mysqlpassword"

# Path to store your wordpress files
WP_CORE="/path/to/your/wordpress/core/files"
WP_CONTENT="/path/to/your/wordpress/wp-content"

# Table prefix
WORDPRESS_TABLE_PREFIX="wp_"

while [ "$1" != "" ]; do
    case $1 in
        -CONTAINER_NAME  )   shift	
            CONTAINER_NAME=$1;;  
        -DOMAINS  )   shift
            DOMAINS=$1;;
        -LETSENCRYPT_EMAIL ) shift
            LETSENCRYPT_EMAIL=$1;;
        -NETWORK ) shift
            NETWORK=$1;;
        -MYSQL_ROOT_PASSWORD ) shift
            MYSQL_ROOT_PASSWORD=$1;;
        -MYSQL_DATABASE ) shift
            MYSQL_DATABASE=$1;;
        -MYSQL_USER ) shift
            MYSQL_USER=$1;;
        -MYSQL_PASSWORD ) shift
            MYSQL_PASSWORD=$1;;
        -WORDPRESS_IMAGE ) shift
            WORDPRESS_IMAGE=$1;;
        -DB_IMAGE ) shift
            DB_IMAGE=$1;;
    esac
shift
done

if [ -z "$CONTAINER_NAME" ]
then
    echo "Please specify -CONTAINER_NAME parameter";
    exit 1;
fi

#
# Database Container configuration
# We recommend MySQL or MariaDB - please update docker-compose file if needed.
#
CONTAINER_DB_NAME="$CONTAINER_NAME_db"

#
# Wordpress Container configuration
#
CONTAINER_WP_NAME="$CONTAINER_NAME_wp"

WEB_BASE_PATH="$INSTALL_DIR/web/$CONTAINER_NAME"

if [ $DB_PATH = "/path/to/your/local/database/folder" ]
then
    DB_PATH="$WEB_BASE_PATH/db"
fi

if [ $WP_CORE = "/path/to/your/wordpress/core/files" ]
then
    WP_CORE="$WEB_BASE_PATH/public"
fi

if [ $WP_CONTENT = "/path/to/your/wordpress/wp-content" ]
then
    WP_CONTENT="$WEB_BASE_PATH/public/wp-content"
fi

if [ -z "$DOMAINS" ]
then
    echo "Please specify -DOMAINS parameter";
    exit 1;
fi

if [ -z "$LETSENCRYPT_EMAIL" ]
then
    echo "Please specify -LETSENCRYPT_EMAIL parameter";
    exit 1;
fi

# Install docker
if ! [ -x "$(command -v docker)" ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-cache policy docker-ce
    apt-get install -y docker-ce
    usermod -aG docker "${USER}"
fi
docker -v

# Install docker-compose
if ! [ -x "$(command -v docker-compose)" ]; then
    curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.15.0/docker-compose-$(uname -s)-$(uname -m)"
    chmod +x /usr/local/bin/docker-compose
fi
docker-compose -v

if [ ! "$(docker ps -q -f name=nginx-web)" ]; then
    COMPANION_INSTALLLED=0;
fi

if [ ! "$(docker ps -q -f name=nginx-gen)" ]; then
    COMPANION_INSTALLLED=0;
fi

if [ ! "$(docker ps -q -f name=nginx-letsencrypt)" ]; then
    COMPANION_INSTALLLED=0;
fi

if [ $COMPANION_INSTALLLED = "0" ]
then
    echo "Installing companion"
    # Stop and remove existing containers
    docker stop nginx-web
    docker rm nginx-web
    docker stop nginx-gen
    docker rm nginx-gen
    docker stop nginx-letsencrypt
    docker rm nginx-letsencrypt

    # Delete existing directories
    echo 'Delete existing directory "docker-compose-letsencrypt-nginx-proxy-companion"'
    rm -rf "$INSTALL_DIR/docker-compose-letsencrypt-nginx-proxy-companion"

    echo 'Delete existing directory "nginx"'
    rm -rf "$INSTALL_DIR/nginx"

    # Clone docker-compose-letsencrypt-nginx-proxy-companion github repo
    git clone https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion.git

    # Copy environtment file
    echo 'Copy "docker-compose-letsencrypt-nginx-proxy-companion/.env.example" to "docker-compose-letsencrypt-nginx-proxy-companion/.env" file'
    yes | cp -f "$INSTALL_DIR/docker-compose-letsencrypt-nginx-proxy-companion/.env.sample" "$INSTALL_DIR/docker-compose-letsencrypt-nginx-proxy-companion/.env"

    # Replace environtment settings
    sed -i "s#/path/to/your/nginx/data#$INSTALL_DIR/nginx-conf#g" "$INSTALL_DIR/docker-compose-letsencrypt-nginx-proxy-companion/.env"

    # Run the docker-compose-letsencrypt-nginx-proxy-companion installer
    cd "$INSTALL_DIR/docker-compose-letsencrypt-nginx-proxy-companion" || exit
    ./start.sh
fi

mkdir -p $WEB_BASE_PATH

yes | cp -f "$INSTALL_DIR/docker-compose.yml.tmpl" "$WEB_BASE_PATH/docker-compose.yml"
yes | cp -f "$INSTALL_DIR/.env.tmpl" "$WEB_BASE_PATH/.env"

sed -i "s/domain.com,www.domain.com/$DOMAINS/g" "$WEB_BASE_PATH/.env"
sed -i "s/user@domain.com/$LETSENCRYPT_EMAIL/g" "$WEB_BASE_PATH/.env"
sed -i "s/mysqlrootpassword/$MYSQL_ROOT_PASSWORD/g" "$WEB_BASE_PATH/.env"
sed -i "s/mysqldatabase/$MYSQL_DATABASE/g" "$WEB_BASE_PATH/.env"
sed -i "s/mysqluser/$MYSQL_USER/g" "$WEB_BASE_PATH/.env"
sed -i "s/mysqlpassword/$MYSQL_PASSWORD/g" "$WEB_BASE_PATH/.env"
sed -i "s/networkname/$NETWORK/g" "$WEB_BASE_PATH/.env"
sed -i "s/mariadb:latest/$DB_IMAGE/g" "$WEB_BASE_PATH/.env"
sed -i "s/containerdbname/$CONTAINER_NAME/g" "$WEB_BASE_PATH/.env"
sed -i "s/wordpress:latest/$WORDPRESS_IMAGE/g" "$WEB_BASE_PATH/.env"
sed -i "s/containerwpname/$CONTAINER_NAME/g" "$WEB_BASE_PATH/.env"

cd $WEB_BASE_PATH || exit

docker-compose up -d