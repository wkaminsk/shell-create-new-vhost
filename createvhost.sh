if [ "$2" = "" ]
then
        echo "Usage: $0 username site-domain"
        exit
fi

USERPASSWD="`cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@#%^&*()' | fold -w 12 | head -n 1`"
MYSQLPASSWD="`cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@%^&*()' | fold -w 12 | head -n 1`"

useradd -m $1
echo $USERPASSWD | passwd $1 --stdin >/dev/null 2>&1
sudo -u  $1 mkdir /home/$1/public_html

chmod 755 /home/$1

echo "
<VirtualHost *:80>

  # Admin email, Server Name (domain name) and any aliases
  ServerAdmin webmaster@domain1.com
  ServerName  $2
  ServerAlias www.$2


  # Index file and Document Root (where the public files are located)
  DirectoryIndex index.php
  DocumentRoot /home/$1/public_html/


  # Custom log file locations
  LogLevel warn
  ErrorLog /var/log/apache2/$2.log
  CustomLog /var/log/apache2/$2.log combined

</VirtualHost>
" > /etc/apache2/sites-available/$1.conf

service nginx restart >/dev/null 2>&1

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
