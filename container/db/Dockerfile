FROM mariadb:11.7

USER mysql:mysql

COPY ./config/db/server.cnf /etc/mysql/mariadb.conf.d/60-server.cnf
COPY ./config/db/galera.cnf /etc/mysql/mariadb.conf.d/60-galera.cnf

COPY ./container/db/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["new_cluster"]
