#!/bin/bash

if [ -z "$SKIP_BACKUP" ]; then
  wait-port -t 60000 localhost:3306

  for i in $(echo $MYSQL_DATABASE | sed "s/,/ /g")
  do
    if [ -r "/backup/$i.sql.gz" ]; then
      gunzip -c /backup/$i.sql.gz | mysql $i
    fi
  done
fi
