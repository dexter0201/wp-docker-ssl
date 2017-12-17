# wp-docker-dev
Install Wordpress in Docker with SSL enabled integrated with NGINX proxy and auto-renew LetsEncrypt certificates. Come with WP_CLI installed.

----------

### How to Use:
 1. Clone this repository:
`git clone https://github.com/sofyansitorus/wp-docker-dev.git`
 2. Then run command:
`./run.sh -c mycontainername -d mydomain.com,www.mydomain.com -e user@emaildomain.com`
 3. Create new DNS A Record pointing to your server IP address.
 4. To install another vhost/domain, just repeat step 2 and 3 above.

----------
### Availabe options/arguments:

 1. `--container_name` or `-c` (Required)
 2. `--domains` or `-d` (Required, Separate with comma for multiple domain)
 3. `--letsencrypt_email` or `-e` (Required)
 4. `--network` or `-n` (Optional, Default = webproxy)
 5. `--mysql_root_password` or `-mr` (Optional, Default = random string 20 characters)
 6. `--mysql_database` or `-md` (Optional, Default = random string 6 characters)
 7. `--mysql_user` or `-mu` (Optional, Default = random string 6 characters)
 8. `--mysql_password` or `-mp` (Optional, Default = random string 20 characters)
 8. `--wordpress_image` or `-wi` (Optional, Default = wordpress:latest, Available tags: https://hub.docker.com/_/wordpress/)
 9. `--db_image` or `-di` (Optional, Default = mariadb:latest, Available tags https://hub.docker.com/_/mariadb/, https://hub.docker.com/_/mysql/)
 10. `--wordpress_table_prefix` or `-t` (Optional, Default = wp_)
