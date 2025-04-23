#!/bin/bash
set -e

if [ "$1" = "new_cluster" ]
then
    echo "---> Starting mariadbd with --wsrep-new-cluster ..."
    exec /usr/local/bin/docker-entrypoint.sh mariadbd --wsrep-new-cluster -vvv
fi

if [ "$1" = "add_cluster" ]
then
    echo "---> Starting mariadbd ..."
    exec /usr/local/bin/docker-entrypoint.sh mariadbd -vvv
fi

exec "$@"
