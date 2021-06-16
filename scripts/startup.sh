#!/bin/sh

MYSQL_USER=${MYSQL_USER:-"username"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"password"}
MYSQL_DATABASE=${MYSQL_DATABASE:-"db"}

mkdir -p /var/lib/mysql/
mkdir -p /var/run/mysqld
mkdir -p /var/log/mysql

chown -Rf mysql:mysql /var/lib/mysql
chown -Rf mysql:mysql /var/log/mysql
chown -Rf mysql:mysql /var/run/mysqld

if [ ! -f /var/lib/mysql/ibdata1 ]; then

  echo "Setting up database"

  /usr/bin/mysql_install_db --datadir=/var/lib/mysql/ --user=mysql --auth-root-authentication-method=normal 2> /dev/null
  /usr/bin/mysqld_safe --defaults-file=/etc/mysql/my.cnf --datadir=/var/lib/mysql/ --user=mysql  &
  c=1
  while [[ $c -le 10 ]]
  do
    echo 'SELECT 1' | /usr/bin/mysql &> /dev/null
    if [ $? -eq 0 ]; then
      break
    fi
    echo "."
    sleep 1
    let c=c+1
  done

  if [ $c -eq 11 ]; then
    echo "database failed to start"
    exit 1
  fi
  if [ ! -z $MYSQL_DATABASE ]; then
    for i in $(echo $MYSQL_DATABASE | sed "s/,/ /g")
    do
      echo "Creating database $i"
      echo "CREATE DATABASE IF NOT EXISTS $i ;" | /usr/bin/mysql
    done
  fi

  if [ ! -z $MYSQL_USER ]; then
    echo "Creating user $MYSQL_USER"
    echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
    echo "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
    if [ ! -z $MYSQL_DATABASE ]; then
      for i in $(echo $MYSQL_DATABASE | sed "s/,/ /g")
      do
        echo "Granting access for $MYSQL_USER to $i"
        echo "GRANT ALL ON $i.* TO '$MYSQL_USER'@'%' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
        echo "GRANT ALL ON $i.* TO '$MYSQL_USER'@'localhost' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
      done
    fi
  fi

  /usr/bin/mysqladmin shutdown
fi

# Update mysql config
BUFFER_SIZE=${BUFFER_SIZE:-"64"}
LOG_SIZE=`node -e "process.stdout.write(''+Math.ceil($BUFFER_SIZE / 4))"`
sed -i "s/innodb_buffer_pool_size = 64M/innodb_buffer_pool_size = ${BUFFER_SIZE}M/g" /etc/mysql/my.cnf
sed -i "s/innodb_log_file_size = 16M/innodb_log_file_size = ${LOG_SIZE}M/g" /etc/mysql/my.cnf
sed -i "s/innodb_log_buffer_size = 16M/innodb_log_file_size = ${LOG_SIZE}M/g" /etc/mysql/my.cnf

# Start server
exec /usr/bin/mysqld --basedir=/usr --datadir=/var/lib/mysql/ --plugin-dir=/usr/lib/mysql/plugin --user=mysql --console --log-error=/var/log/mysql/mysql.err --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=3306
