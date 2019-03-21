FROM alpine:3.9

RUN apk add --update mariadb mariadb-client nodejs nodejs-npm \
 && npm install -g wait-port \
 && apk del nodejs-npm \
 && rm -f /var/cache/apk/*

COPy my.cnf /etc/mysql/
COPY scripts/ /var/scripts/

LABEL flush="sh /var/scripts/flush.sh" \
      backup="sh /var/scripts/backup.sh" \
      restore="sh /var/scripts/restore.sh"

EXPOSE 3306
CMD ["/var/scripts/startup.sh"]
