FROM alpine:3.7

RUN apk add --update mysql mysql-client nodejs \
 && rm -f /var/cache/apk/* \
 && npm install -g wait-port

COPY my.cnf /etc/mysql/my.cnf
COPY scripts/ /var/scripts/

LABEL flush="sh /var/scripts/flush.sh" \
      backup="sh /var/scripts/backup.sh" \
      restore="sh /var/scripts/restore.sh"

EXPOSE 3306
CMD ["/var/scripts/startup.sh"]
