FROM mysql:5.6

ADD triton-entrypoint.sh /triton-entrypoint.sh
RUN chmod +x /triton-entrypoint.sh

ENTRYPOINT ["/triton-entrypoint.sh"]
CMD ["mysqld", "--relay-log=mysqld-relay-bin"]
