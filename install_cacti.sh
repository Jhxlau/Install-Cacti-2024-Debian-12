#!/bin/sh

export PHPVERSION=8.2

sudo timedatectl set-timezone Asia/Jakarta
echo "----------------------------------------------------"
echo " START INSTALLING THE LATEST CACTI DEBIAN 12 "
echo "----------------------------------------------------"
sleep 2
echo ""
echo "----------------------------------------------------"
echo " update and upgrade "
echo "----------------------------------------------------"
apt update && apt upgrade -y

sleep 2
echo "----------------------------------------------------"
echo "Install Cacti support package"
echo "----------------------------------------------------"
apt install cron snmp php-snmp rrdtool librrds-perl unzip curl git gnupg2 -y

sleep 2
echo "----------------------------------------------------"
echo "Install LAMP Server"
echo "----------------------------------------------------"
apt install apache2 mariadb-server  php8.2 libapache2-mod-php -y
apt install -y php${PHPVERSION}-{mysql,xml,ldap,mbstring,gd,gmp,intl}

sleep 2
echo "----------------------------------------------------"
echo "Config Apache"
echo "----------------------------------------------------"

sleep 2
sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php/8.2/apache2/php.ini

sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php/8.2/apache2/php.ini

sed -i 's/;date.timezone =/date.timezone = Asia\/Jakarta/g' /etc/php/8.2/apache2/php.ini

sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php/8.2/cli/php.ini

sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php/8.2/cli/php.ini

sed -i 's/;date.timezone =/date.timezone = Asia\/Jakarta/g' /etc/php/8.2/cli/php.ini

systemctl restart apache2

echo "----------------------------------------------------"
echo "Config MySQL"
echo "----------------------------------------------------"

sleep 2
sed -i 's/collation-server      = utf8mb4_general_ci/collation-server      = utf8mb4_unicode_ci/g' /etc/mysql/mariadb.conf.d/50-server.cnf

cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << EOF
max_heap_table_size = 128M
tmp_table_size = 128M
join_buffer_size = 1M
innodb_file_format = Barracuda
innodb_large_prefix = 1
innodb_buffer_pool_size = 2048M
innodb_flush_log_at_timeout = 3
innodb_read_io_threads = 32
innodb_write_io_threads = 16
innodb_io_capacity = 5000
innodb_io_capacity_max = 10000
innodb_doublewrite = OFF
sort_buffer_size = 1M
EOF

systemctl restart mariadb

echo "----------------------------------------------------"
echo "  Database Name  "
echo "----------------------------------------------------"
sleep 2

read -p "cactidb ​​example: " namadb

mysqladmin -uroot create $namadb

echo "----------------------------------------------------"
echo "  Password Database  "
echo "----------------------------------------------------"
sleep 2

read -p "enter password for database: " passdb

mysql -uroot -e "grant all on $namadb.* to 'cactiuser'@'localhost' identified by '$passdb'"

mysql -uroot -e "flush privileges"

mysql mysql < /usr/share/mysql/mysql_test_data_timezone.sql

mysql -uroot -e "GRANT SELECT ON mysql.time_zone_name TO 'cactiuser'@'localhost'"

mysql -uroot -e "flush privileges"

rm -rf /var/www/html/index.html

echo "----------------------------------------------------"
echo " download cacti latest version "
echo "----------------------------------------------------"
sleep 2

if [ ! -f 'cacti-latest.tar.gz' ]; then
    wget https://www.cacti.net/downloads/cacti-latest.tar.gz --no-check-certificate
fi 

echo "----------------------------------------------------"
echo " Cacti Extract "
echo "----------------------------------------------------"
sleep 2

tar -zxvf cacti-latest.tar.gz

echo "----------------------------------------------------"
echo " Copy Cacti to Folder /var/www/html"
echo "----------------------------------------------------"
sleep 2

cp -a cacti-1*/. /var/www/html

chown -R www-data:www-data /var/www/html/

chmod -R 775 /var/www/html/

mysql $namadb < /var/www/html/cacti.sql

cp /var/www/html/include/config.php.dist /var/www/html/include/config.php

sed -i 's/database_default  = '\''cacti/database_default  = '\'''$namadb'/g' /var/www/html/include/config.php

sed -i 's/database_password = '\''cactiuser/database_password = '\'''$passdb'/g' /var/www/html/include/config.php

sed -i 's/url_path = '\''\/cacti/url_path = '\''/g' /var/www/html/include/config.php

echo "----------------------------------------------------"
echo " Add cacti in cronjob"
echo "----------------------------------------------------"
sleep 2
touch /etc/cron.d/cacti
cat >> /etc/cron.d/cacti << EOF
*/5 * * * * www-data php /var/www/html/poller.php > /dev/null 2>&1
EOF

chmod +x /etc/cron.d/cacti
echo "===================================================="
echo " *** FINISH *** "
echo " cacti installed in folder /var/www/html "
echo " please continue cacti login http://"`hostname -I | awk '{print $1}'`
echo " username: admin password: admin "
echo "===================================================="
