#!/bin/sh

# Update mysql config
BUFFER_SIZE=${BUFFER_SIZE:-"64"}
LOG_SIZE=`node -e "process.stdout.write(''+Math.ceil($BUFFER_SIZE / 4))"`
sed -i "s/innodb_buffer_pool_size = 64M/innodb_buffer_pool_size = ${BUFFER_SIZE}M/g" /etc/mysql/my.cnf
sed -i "s/innodb_log_file_size = 16M/innodb_log_file_size = ${LOG_SIZE}M/g" /etc/mysql/my.cnf
sed -i "s/innodb_log_buffer_size = 16M/innodb_log_file_size = ${LOG_SIZE}M/g" /etc/mysql/my.cnf

if [ -d /run/mysqld ]; then
  echo "[i] MySQL directory already present, skipping creation"
else
  echo "[i] MySQL data directory not found, creating initial DBs"

  mysql_install_db --user=root > /dev/null

  if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
    MYSQL_ROOT_PASSWORD=`date | sha256sum | base64 | head -c 32`
  fi

  MYSQL_DATABASE=${MYSQL_DATABASE:-""}
  MYSQL_USER=${MYSQL_USER:-"username"}
  MYSQL_PASSWORD=${MYSQL_PASSWORD:-"password"}

  if [ ! -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld
  fi

  tfile=`mktemp`
  if [ ! -f "$tfile" ]; then
      return 1
  fi

  cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
EOF

  if [ "$MYSQL_DATABASE" != "" ]; then

    for i in $(echo $MYSQL_DATABASE | sed "s/,/ /g")
    do
      echo "$i"
      echo "[i] Creating database: $i"
      echo "CREATE DATABASE IF NOT EXISTS \`$i\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile
      echo "GRANT ALL ON \`$i\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
    done

  fi

  /usr/bin/mysqld --user=root --bootstrap --verbose=0 < $tfile
  rm -f $tfile
fi

exec /usr/bin/mysqld --user=root --console
