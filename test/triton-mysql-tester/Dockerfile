FROM mysql:5.6

ADD test-entrypoint.sh /test-entrypoint.sh
RUN chmod +x /test-entrypoint.sh

ENTRYPOINT ["/test-entrypoint.sh"]

