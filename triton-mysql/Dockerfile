FROM mysql:5.6

# Install Percona XtraBackup (optionally used to clone mysql master)
#
#RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A \
#RUN export VERSION=$(awk -F"[)(]+" '/VERSION=/ {print $2}' /etc/os-release) \
# && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C4CBDCDCD2EFD2A \
# && echo "deb http://repo.percona.com/apt $VERSION main" >> /etc/apt/sources.list \
# && echo "deb-src http://repo.percona.com/apt $VERSION main" >> /etc/apt/sources.list \
# && cat /etc/apt/sources.list \
# && apt-get update \
# && apt-get install -y procps \
# && apt-get install -y percona-xtrabackup \
# && apt-get clean \
# && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;


ADD triton-entrypoint.sh /triton-entrypoint.sh
RUN chmod +x /triton-entrypoint.sh

ADD mysql-clone-tool.sh /mysql-clone-tool.sh
ADD archive.sh /archive.sh

ENTRYPOINT ["/triton-entrypoint.sh"]
CMD ["mysqld", "--relay-log=mysqld-relay-bin"]
