#!/bin/bash

wait-port -t 60000 localhost:3306
mysqldump $MYSQL_DATABASE | gzip -f > /backup/mysql.sql.gz
