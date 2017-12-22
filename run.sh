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
DATABASE_IMAGE="mariadb:latest"

WORDPRESS_ADMIN_USER="changeme"
WORDPRESS_ADMIN_PASSWORD="changeme"
WORDPRESS_SITE_TITLE="Just another WordPress site"

# Assign variables from arguments
while [ "$1" != "" ]; do
    case $1 in
        --container |-c ) shift	
            CONTAINER=$1
            ;;  
        --domains |-d )   shift
            DOMAINS=$1
            ;;
        --email |-e ) shift
            EMAIL=$1
            ;;
        --network |-n ) shift
            NETWORK=$1
            ;;
        --mysql_root_password |-mrp ) shift
            MYSQL_ROOT_PASSWORD=$1
            ;;
        --mysql_database |-md ) shift
            MYSQL_DATABASE=$1
            ;;
        --mysql_user |-mu ) shift
            MYSQL_USER=$1
            ;;
        --mysql_password |-mp ) shift
            MYSQL_PASSWORD=$1
            ;;
        --wordpress_image |-wpi ) shift
            WORDPRESS_IMAGE=$1
            ;;
        --database_image |-dbi ) shift
            DATABASE_IMAGE=$1
            ;;
        --wordpress_table_prefix |-wtp ) shift
            WORDPRESS_TABLE_PREFIX=$1
            ;;
        --wordpress_admin_user |-wau ) shift
            WORDPRESS_ADMIN_USER=$1
            ;;
        --wordpress_admin_password |-wap ) shift
            WORDPRESS_ADMIN_PASSWORD=$1
            ;;
        --wordpress_site_title |-wst ) shift
            WORDPRESS_SITE_TITLE=$1
            ;;
    esac
shift
done

if [ -z "$DOMAINS" ]
then
    echo "Please specify --domains parameter"
    exit 1
fi

if [ -z "$EMAIL" ]
then
    echo "Please specify --email parameter"
    exit 1
fi

if [ -z "$CONTAINER" ]
then
    CONTAINER="$(cut -d',' -f1 <<<"$DOMAINS")"
fi

CONTAINER_DB="_db"
CONTAINER_DB="$CONTAINER$CONTAINER_DB"

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
    INSTALL_COMPANION=1
fi

if [ ! "$(docker ps -aq -f status=running -f name=nginx-gen)" ]; then
    INSTALL_COMPANION=1
fi

if [ ! "$(docker ps -aq -f status=running -f name=nginx-letsencrypt)" ]; then
    INSTALL_COMPANION=1
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
    sed -i "s#=webproxy#=$NETWORK#g" "$INSTALL_DIR/$COMPANION_DIR/.env"
    sed -i "s#=/path/to/your/nginx/data#=$INSTALL_DIR/nginx-conf#g" "$INSTALL_DIR/$COMPANION_DIR/.env"

    # Run the docker-compose-letsencrypt-nginx-proxy-companion installer
    cd "$INSTALL_DIR/$COMPANION_DIR" || exit
    ./start.sh
fi

# Set Web base path variable
WEB_BASE_PATH="$INSTALL_DIR/web/$CONTAINER"

# Create Web base path directory
mkdir -p $WEB_BASE_PATH

# Copy Dockerfile template file
yes | cp -f "$INSTALL_DIR/src/Dockerfile" "$WEB_BASE_PATH/Dockerfile"

# Replace Dockerfile environtment settings
sed -i "s#wordpress_image#$WORDPRESS_IMAGE#g" "$WEB_BASE_PATH/Dockerfile"

# Copy docker-compose.yml template file
yes | cp -f "$INSTALL_DIR/src/docker-compose.yml" "$WEB_BASE_PATH/docker-compose.yml"

# Copy .env template file
yes | cp -f "$INSTALL_DIR/src/.env" "$WEB_BASE_PATH/.env"

# Replace docker-compose file environtment settings
sed -i "s#=containername#=$CONTAINER#g" "$WEB_BASE_PATH/.env"
sed -i "s#=domain.com,www.domain.com#=$DOMAINS#g" "$WEB_BASE_PATH/.env"
sed -i "s#=user@domain.com#=$EMAIL#g" "$WEB_BASE_PATH/.env"
sed -i "s#=mariadb:latest#=$DATABASE_IMAGE#g" "$WEB_BASE_PATH/.env"
sed -i "s#=wordpress:latest#=$WORDPRESS_IMAGE#g" "$WEB_BASE_PATH/.env"
sed -i "s#=networkname#=$NETWORK#g" "$WEB_BASE_PATH/.env"
sed -i "s#=mysqlrootpassword#=$MYSQL_ROOT_PASSWORD#g" "$WEB_BASE_PATH/.env"
sed -i "s#=mysqldatabase#=$MYSQL_DATABASE#g" "$WEB_BASE_PATH/.env"
sed -i "s#=mysqluser#=$MYSQL_USER#g" "$WEB_BASE_PATH/.env"
sed -i "s#=mysqlpassword#=$MYSQL_PASSWORD#g" "$WEB_BASE_PATH/.env"
sed -i "s#=wp_tbl_#=$WORDPRESS_TABLE_PREFIX#g" "$WEB_BASE_PATH/.env"

# Change directory to Web base path
cd $WEB_BASE_PATH || exit

# Try to stop existing running containers
sudo `which docker-compose` stop

# Builds, (re)creates, starts, and attaches to containers for a service.
sudo `which docker-compose` up -d --build

cd $INSTALL_DIR || exit

WORDPRESS_URL="$(cut -d',' -f1 <<<"$DOMAINS")"

./wait.sh -h $CONTAINER_DB -p 3306 -t 15 -- sudo `which docker` exec -u www-data $CONTAINER wp core install --path=/var/www/html --url=$WORDPRESS_URL --admin_email=$EMAIL --admin_user=$WORDPRESS_ADMIN_USER --admin_password=$WORDPRESS_ADMIN_PASSWORD --title="$WORDPRESS_SITE_TITLE" --skip-email
