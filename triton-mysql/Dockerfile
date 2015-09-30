FROM mysql:5.7

ADD triton-entrypoint.sh /triton-entrypoint.sh
RUN chmod +x /triton-entrypoint.sh

ENTRYPOINT ["/triton-entrypoint.sh"]
CMD ["mysqld"]
