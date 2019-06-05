#!/bin/bash

MYSQL_DATABASE=${MYSQL_DATABASE:-"db"}

if [ -z "$SKIP_BACKUP" ]; then
  wait-port -t 60000 localhost:3306

  for i in $(echo $MYSQL_DATABASE | sed "s/,/ /g")
  do
    for j in $(echo "1,2,3,4,5,6" | sed "s/,/ /g")
    do
      TABLECOUNT=`echo "show tables;" | mysql $i | wc | awk '{print $1}'`
      if [ $TABLECOUNT == "0" ]; then
        echo "Waiting for mysql to startup... ($j/6)"
        sleep 10
      fi
    done
    mysqldump $i | gzip -f > /backup/$i.sql.gz
  done
fi
