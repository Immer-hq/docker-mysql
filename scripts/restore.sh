#!/bin/bash

wait-port -t 60000 localhost:3306
gunzip -c /backup/mysql.sql.gz | mysql $MYSQL_DATABASE
