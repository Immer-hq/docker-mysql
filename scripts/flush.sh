#!/bin/sh

wait-port -t 60000 localhost:3306
echo 'FLUSH TABLES;' | mysql
