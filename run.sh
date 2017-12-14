#!/bin/bash

while [ "$1" != "" ]; do
    case $1 in
        -c  )   shift	
            CONTAINER_NAME=$1;;  
        -d  )   shift
            DOMAIN=$1;;
        --paramter|p ) shift
            PARAMETER=$1;;
    esac
shift
done

if [ -z "$CONTAINER_NAME" ]
then
    echo "Please specify container name parameter";
    exit 1;
fi

if [ -z "$DOMAIN" ]
then
    echo "Please specify domain name parameter";
    exit 1;
fi

INSTALL_DIR=$PWD

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