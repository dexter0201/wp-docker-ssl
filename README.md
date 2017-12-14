# wp-docker-dev
Install Wordpress in Docker with SSL enabled integrated with NGINX proxy and auto-renew LetsEncrypt certificates.

----------

### How to Use:
 1. Clone this repository:
`git clone https://github.com/sofyansitorus/wp-docker-dev.git`
 2. Then run command:
`./run.sh --CONTAINER_NAME mywpcontainer --DOMAINS mydomain.com,www.mydomain.com --LETSENCRYPT_EMAIL user@mydomain.com`
 3. To install another vhost/domain, just repeat command above with different arguments value.

----------
### Availabe options/arguments:

 1. `--CONTAINER_NAME` (Required)
 2. `--DOMAINS` (Required)
 3. `--LETSENCRYPT_EMAIL` (Required)
 4. `--NETWORK` (Optional, Default = webproxy)
 5. `--MYSQL_ROOT_PASSWORD` (Optional, Default = random string 20 characters)
 6. `--MYSQL_DATABASE` (Optional, Default = random string 6 characters)
 7. `--MYSQL_USER` (Optional, Default = random string 6 characters)
 8. `--MYSQL_PASSWORD` (Optional, Default = random string 20 characters)
 8. `--WORDPRESS_IMAGE` (Optional, Default = wordpress:latest)
 9. `--DB_IMAGE` (Optional, Default = mariadb:latest)
