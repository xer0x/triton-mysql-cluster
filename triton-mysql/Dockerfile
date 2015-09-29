FROM mysql:5.7

ADD triton-entrypoint.sh /triton-entrypoint.sh
RUN chmod +x /triton-entrypoint.sh

COPY create_replication_user.sql /docker-entrypoint-initdb.d/create_replication_user.sql

ENTRYPOINT ["/triton-entrypoint.sh"]
CMD ["mysqld"]
