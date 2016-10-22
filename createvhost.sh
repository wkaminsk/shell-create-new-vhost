#!/bin/bash
webmasterEmail='webmaster@domain1.com'

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run this script."
		exit 1;
fi

if [ "$2" = "" ]
then
        echo "Wrong data entered."
        exit
fi

### Create random passwords for linux user and mysql user

USERPASSWD="`cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@#%^&*()' | fold -w 12 | head -n 1`"
MYSQLPASSWD="`cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@%^&*()' | fold -w 12 | head -n 1`"

### Create new user

useradd -m $1
echo $USERPASSWD | passwd $1 --stdin >/dev/null 2>&1

### Add rights for user
chmod 755 /home/$1
sudo -u  $1 mkdir /home/$1/public_html

### Create new vhost conf file
echo "
<VirtualHost *:80>

  # Admin email, Server Name (domain name) and any aliases
  ServerAdmin webmasterEmail
  ServerName  $2
  ServerAlias www.$2


  # Index file and Document Root (where the public files are located)
  DirectoryIndex index.php
  DocumentRoot /home/$1/public_html/


  # Custom log file locations
  LogLevel warn
  ErrorLog /var/log/apache2/$2.log
  CustomLog /var/log/apache2/$2.log combined
	<Directory />
		AllowOverride All
	</Directory>
	<Directory /home/$1/public_html/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride all
		Require all granted
	</Directory>

</VirtualHost>
" > /etc/apache2/sites-enabled/$1.conf

a2ensite $2
/etc/init.d/apache2 reload

### Add domain in /etc/hosts
echo "127.0.0.1	$2" >> /etc/hosts

mysql -u root -p -e "CREATE DATABASE $1; GRANT ALL PRIVILEGES ON $1.* TO $1@localhost IDENTIFIED BY \"$MYSQLPASSWD\""
echo "
Created vhost:  $2

SSH credentials:
u: $1
p: $USERPASSWD

Database credentials:
db: $1
user: $1
pass: $MYSQLPASSWD"
