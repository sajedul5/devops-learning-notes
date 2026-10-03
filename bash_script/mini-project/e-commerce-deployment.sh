#!/bin/bash
#
# Automate ECommerce Application Deployment (CentOS/RHEL, single host)
# Author: Md Sajedul Islam
#
# Usage:
#   export DB_PASSWORD='a-strong-password'      # never hardcode passwords in scripts
#   export REPO_URL='https://github.com/<you>/learning-app-ecommerce.git'
#   ./e-commerce-deployment.sh
#
# Security notes:
#   - The DB password comes from the environment and is sent to MySQL via stdin
#     (heredoc), so it is never written to a .sql file on disk.
#   - The app user only gets privileges on its own database (least privilege).
#   - Port 3306 is NOT opened in the firewall: web server and DB are on the same
#     host, so MariaDB only needs to be reachable on localhost.

set -euo pipefail

: "${DB_PASSWORD:?Set DB_PASSWORD, e.g. export DB_PASSWORD=\$(openssl rand -base64 18)}"
: "${REPO_URL:?Set REPO_URL to the git URL of the e-commerce app}"

#######################################
# Print a message in a given color.
# Arguments:
#   Color. eg: green, red
#######################################
function print_color(){
  NC='\033[0m' # No Color

  case $1 in
    "green") COLOR='\033[0;32m' ;;
    "red") COLOR='\033[0;31m' ;;
    *) COLOR='\033[0m' ;;
  esac

  echo -e "${COLOR} $2 ${NC}"
}

#######################################
# Check the status of a given service. If not active exit script
# Arguments:
#   Service Name. eg: firewalld, mariadb
#######################################
function check_service_status(){
  service_is_active=$(sudo systemctl is-active "$1" || true)

  if [ "$service_is_active" = "active" ]
  then
    echo "$1 is active and running"
  else
    echo "$1 is not active/running"
    exit 1
  fi
}

#######################################
# Check the status of a firewalld rule. If not configured exit.
# Arguments:
#   Port Number. eg: 3306, 80
#######################################
function is_firewalld_rule_configured(){

  firewalld_ports=$(sudo firewall-cmd --list-all --zone=public | grep ports || true)

  if [[ $firewalld_ports == *$1* ]]
  then
    echo "FirewallD has port $1 configured"
  else
    echo "FirewallD port $1 is not configured"
    exit 1
  fi
}

#######################################
# Check if a given item is present in an output
# Arguments:
#   1 - Output
#   2 - Item
#######################################
function check_item(){
  if [[ $1 = *$2* ]]
  then
    print_color "green" "Item $2 is present on the web page"
  else
    print_color "red" "Item $2 is not present on the web page"
  fi
}






echo "---------------- Setup Database Server ------------------"

# Install and configure firewalld
print_color "green" "Installing FirewallD.. "
sudo yum install -y firewalld

print_color "green" "Installing FirewallD.. "
sudo service firewalld start
sudo systemctl enable firewalld

# Check FirewallD Service is running
check_service_status firewalld

# Install and configure Maria-DB
print_color "green" "Installing MariaDB Server.."
sudo yum install -y mariadb-server

print_color "green" "Starting MariaDB Server.."
sudo service mariadb start
sudo systemctl enable mariadb

# Check FirewallD Service is running
check_service_status mariadb

# The database is only used locally, so port 3306 stays CLOSED in the firewall.
# (Open it only if the web server runs on a different host — and then only for
#  that host's IP, e.g. with a firewalld rich rule.)


# Configuring Database
print_color "green" "Setting up database.."
# Escape single quotes for use inside a SQL string literal.
DB_PASSWORD_SQL=${DB_PASSWORD//\'/\'\'}
sudo mysql <<EOF
  CREATE DATABASE IF NOT EXISTS ecomdb;
  CREATE USER IF NOT EXISTS 'ecomuser'@'localhost' IDENTIFIED BY '${DB_PASSWORD_SQL}';
  GRANT ALL PRIVILEGES ON ecomdb.* TO 'ecomuser'@'localhost';
  FLUSH PRIVILEGES;
EOF

# Loading inventory into Database
print_color "green" "Loading inventory data into database"
sudo mysql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

mysql_db_results=$(sudo mysql -e "use ecomdb; select * from products;")

if [[ $mysql_db_results == *Laptop* ]]
then
  print_color "green" "Inventory data loaded into MySQl"
else
  print_color "red" "Inventory data not loaded into MySQl"
  exit 1
fi


print_color "green" "---------------- Setup Database Server - Finished ------------------"

print_color "green" "---------------- Setup Web Server ------------------"

# Install web server packages
print_color "green" "Installing Web Server Packages .."
# php-mysqlnd on Rocky/Alma/RHEL 8+, php-mysql on CentOS 7
sudo yum install -y httpd php php-mysqlnd || sudo yum install -y httpd php php-mysql

# Configure firewalld rules
print_color "green" "Configuring FirewallD rules.."
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

is_firewalld_rule_configured 80

# Update index.php
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

# Start httpd service
print_color "green" "Start httpd service.."
sudo service httpd start
sudo systemctl enable httpd

# Check FirewallD Service is running
check_service_status httpd

# Download code
print_color "green" "Install GIT.."
sudo yum install -y git
sudo git clone "$REPO_URL" /var/www/html/

print_color "green" "Updating index.php.."
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

# Give the app its DB credentials via a .env file readable only by root/Apache.
# (Make sure .env is never committed to the app's own git repo.)
print_color "green" "Writing /var/www/html/.env .."
sudo tee /var/www/html/.env >/dev/null <<EOF
DB_HOST=localhost
DB_USER=ecomuser
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=ecomdb
EOF
sudo chown root:apache /var/www/html/.env
sudo chmod 640 /var/www/html/.env

print_color "green" "---------------- Setup Web Server - Finished ------------------"

# Test Script
web_page=$(curl http://localhost)

for item in Laptop Drone VR Watch Phone
do
  check_item "$web_page" $item
done