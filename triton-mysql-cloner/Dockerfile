FROM gliderlabs/alpine:3.1
RUN apk --update add mysql-client perl perl-dbd-mysql xtrabackup
ADD start.sh /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["start.sh"]
