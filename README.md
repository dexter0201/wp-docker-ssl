# wp-docker-ssl
Install Wordpress in Docker with SSL enabled integrated with NGINX proxy and auto-renew LetsEncrypt certificates. Come with WP-CLI installed.

----------
## How to Install:
 Clone this repository: `git clone https://github.com/sofyansitorus/wp-docker-ssl.git`
 
## Create new WP Site:
 1. Go to git clone directory: `cd wp-docker-ssl`
 2. Run command:
`./run.sh -d mydomain.com,www.mydomain.com -e user@emaildomain.com`
 3. Create new DNS A Record pointing to your server IP address.
 4. To install another vhost/domain, just repeat step 2 and 3 above.
 
##### Availabe options/arguments:
 1. `--domains` or `-d` (Required, Separate with comma for multiple domain)
 2. `--email` or `-e` (Required)
 3. `--container` or `-c` (Optional, Default = domain parameter)
 4. `--network` or `-n` (Optional, Default = webproxy)
 5. `--mysql_root_password` or `-mrp` (Optional, Default = random string 20 characters)
 6. `--mysql_database` or `-md` (Optional, Default = random string 6 characters)
 7. `--mysql_user` or `-mu` (Optional, Default = random string 6 characters)
 8. `--mysql_password` or `-mp` (Optional, Default = random string 20 characters)
 8. `--wordpress_image` or `-wpi` (Optional, Default = wordpress:latest, Available tags: https://hub.docker.com/_/wordpress/)
 9. `--database_image` or `-dbi` (Optional, Default = mariadb:latest, Available tags https://hub.docker.com/_/mariadb/, https://hub.docker.com/_/mysql/)
 10. `--wordpress_table_prefix` or `-wtp` (Optional, Default = wp_)
 11. `--wordpress_admin_user` or `-wau` (Optional, Default = changeme)
 12. `--wordpress_admin_password` or `-wap` (Optional, Default = changeme)
 13. `--wordpress_site_title` or `-wst` (Optional, Default = Just another WordPress site)

## Execute WP-CLI command:

Run command: `./wp.sh containername any-wp-cli-command --wp-cli-args`

##### Example:

`./wp.sh containername plugin install bbpress --activate`

### Credits

 1. [evertramos/docker-compose-letsencrypt-nginx-proxy-companion](https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion)
 2. [vishnubob/wait-for-it](https://github.com/vishnubob/wait-for-it)
