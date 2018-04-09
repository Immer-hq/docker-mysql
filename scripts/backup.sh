#!/bin/bash

if [ -z "$SKIP_BACKUP" ]; then
  wait-port -t 60000 localhost:3306

  for i in $(echo $MYSQL_DATABASE | sed "s/,/ /g")
  do
    mysqldump $i | gzip -f > /backup/$i.sql.gz
  done

  # Old backup scripts writes to mysql.sql.gz.
  if [ -w /backup/mysql.sql.gz ]; then
    rm -f /backup/mysql.sql.gz
  fi
fi
