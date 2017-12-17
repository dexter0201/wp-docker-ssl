#!/bin/bash

INSTALL_DIR=$PWD
INSTALL_COMPANION=0

#
# Network name
# 
# Your container app must use a network conencted to your webproxy 
# https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion
#
NETWORK="webproxy"

# Root password for your database
MYSQL_ROOT_PASSWORD=$(cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 20)

# Database name, user and password for your wordpress
MYSQL_DATABASE=$(cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 6)
MYSQL_USER=$(cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 6)
MYSQL_PASSWORD=$(cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 20)

# Table prefix
WORDPRESS_TABLE_PREFIX="wp_"

# WordPress docker image
WORDPRESS_IMAGE="wordpress:latest"

# DB Dockeer image
DB_IMAGE="mariadb:latest"

# Assign variables from arguments
while [ "$1" != "" ]; do
    case $1 in
        --CONTAINER_NAME |-c )   shift	
            CONTAINER_NAME=$1;;  
        --DOMAINS |-d )   shift
            DOMAINS=$1;;
        --LETSENCRYPT_EMAIL |-e ) shift
            LETSENCRYPT_EMAIL=$1;;
        --NETWORK |-n ) shift
            NETWORK=$1;;
        --MYSQL_ROOT_PASSWORD |-mr ) shift
            MYSQL_ROOT_PASSWORD=$1;;
        --MYSQL_DATABASE |-md ) shift
            MYSQL_DATABASE=$1;;
        --MYSQL_USER |-mu ) shift
            MYSQL_USER=$1;;
        --MYSQL_PASSWORD |-mp ) shift
            MYSQL_PASSWORD=$1;;
        --WORDPRESS_IMAGE |-wi ) shift
            WORDPRESS_IMAGE=$1;;
        --DB_IMAGE |-di ) shift
            DB_IMAGE=$1;;
        --WORDPRESS_TABLE_PREFIX |-t ) shift
            WORDPRESS_TABLE_PREFIX=$1;;
    esac
shift
done

if [ -z "$CONTAINER_NAME" ]
then
    echo "Please specify --CONTAINER_NAME parameter";
    exit 1;
fi

if [ -z "$DOMAINS" ]
then
    echo "Please specify --DOMAINS parameter";
    exit 1;
fi

if [ -z "$LETSENCRYPT_EMAIL" ]
then
    echo "Please specify --LETSENCRYPT_EMAIL parameter";
    exit 1;
fi

# Install docker
if ! [ -x "$(command -v docker)" ]; then
    echo "Docker Engine is not installed. Please visit https://docs.docker.com/engine/installation/ to install Docker"
    exit 1
fi
docker -v

# Install docker-compose
if ! [ -x "$(command -v docker-compose)" ]; then
    echo "Docker Compose is not installed. Please visit https://docs.docker.com/compose/install/ to install Docker Compose"
    exit 1
fi
docker-compose -v

# Check and install docker-compose-letsencrypt-nginx-proxy-companion
if [ ! "$(docker ps -aq -f status=running -f name=nginx-web)" ]; then
    INSTALL_COMPANION=1;
fi

if [ ! "$(docker ps -aq -f status=running -f name=nginx-gen)" ]; then
    INSTALL_COMPANION=1;
fi

if [ ! "$(docker ps -aq -f status=running -f name=nginx-letsencrypt)" ]; then
    INSTALL_COMPANION=1;
fi

if [ $INSTALL_COMPANION = "1" ]
then
    COMPANION_DIR="companion"
    # Stop and remove existing containers
    if [ "$(docker ps -aq -f status=running -f name=nginx-web)" ]; then
        docker stop nginx-web
    fi
    if [ "$(docker ps -q -f name=nginx-web)" ]; then
        docker rm nginx-web
    fi
    if [ "$(docker ps -aq -f status=running -f name=nginx-gen)" ]; then
        docker stop nginx-gen
    fi
    if [ "$(docker ps -q -f name=nginx-gen)" ]; then
        docker rm nginx-gen
    fi
    if [ "$(docker ps -aq -f status=running -f name=nginx-letsencrypt)" ]; then
        docker stop nginx-letsencrypt
    fi
    if [ "$(docker ps -q -f name=nginx-letsencrypt)" ]; then
        docker rm nginx-letsencrypt
    fi

    # Delete existing docker-compose-letsencrypt-nginx-proxy-companion directory
    rm -rf "$INSTALL_DIR/$COMPANION_DIR"

    # Delete existing nginx-conf directory
    rm -rf "$INSTALL_DIR/nginx-conf"

    # Clone docker-compose-letsencrypt-nginx-proxy-companion github repo
    git clone https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion.git $COMPANION_DIR

    # Copy environtment file
    yes | cp -f "$INSTALL_DIR/$COMPANION_DIR/.env.sample" "$INSTALL_DIR/$COMPANION_DIR/.env"

    # Replace docker-compose-letsencrypt-nginx-proxy-companion environtment settings
    sed -i "s#/path/to/your/nginx/data#$INSTALL_DIR/nginx-conf#g" "$INSTALL_DIR/$COMPANION_DIR/.env"

    # Run the docker-compose-letsencrypt-nginx-proxy-companion installer
    cd "$INSTALL_DIR/$COMPANION_DIR" || exit
    ./start.sh
fi

# Set Web base path variable
WEB_BASE_PATH="$INSTALL_DIR/web/$CONTAINER_NAME"

# Create Web base path directory
mkdir -p $WEB_BASE_PATH

# Copy docker-compose.yml template file
yes | cp -f "$INSTALL_DIR/docker-compose.yml.tmpl" "$WEB_BASE_PATH/docker-compose.yml"

# Copy .env template file
yes | cp -f "$INSTALL_DIR/.env.tmpl" "$WEB_BASE_PATH/.env"

# Replace environtment settings
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
sed -i "s/wp_tbl_/$WORDPRESS_TABLE_PREFIX/g" "$WEB_BASE_PATH/.env"

# Change directory to Web base path
cd $WEB_BASE_PATH || exit

# Execute docker-compose.yml file
docker-compose up -d
