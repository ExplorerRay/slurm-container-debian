#!/bin/bash
set -e

if [ ! -f /etc/slurm/slurm.key ]; then
    dd if=/dev/random of=/etc/slurm/slurm.key bs=1024 count=1
fi
chmod 600 /etc/slurm/slurm.key
chown -R slurm:slurm /var/log/slurm /etc/slurm

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting the Slurm Database Daemon (slurmdbd) ..."

    {
        . /etc/slurm/slurmdbd.conf
        until echo "SELECT 1" | mysql -h $StorageHost -u$StorageUser -p$StoragePass 2>&1 > /dev/null
        do
            echo "-- Waiting for database to become active ..."
            sleep 2
        done
    }
    echo "-- Database is now active ..."

    exec sudo -u slurm slurmdbd -Dvvv
fi

if [ "$1" = "slurmctld" ]
then
    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."

    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."

    exec sudo -u slurm slurmctld -i -Dvvv
fi

if [ "$1" = "slurmrestd" ]
then
    # get cluster info with hostname
    CLUSTER_NAME=$(hostname | sed 's/^[^-]*-//' | grep "cluster")
    if [ -z "$CLUSTER_NAME" ]; then
        DEPDENDENCY_NAME="slurmctld"
    else
        DEPDENDENCY_NAME="slurmctld-$CLUSTER_NAME"
    fi

    echo "---> Waiting for $DEPDENDENCY_NAME to become active before starting slurmrestd..."

    until 2>/dev/null >/dev/tcp/"$DEPDENDENCY_NAME"/6817
    do
        echo "-- $DEPDENDENCY_NAME is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- $DEPDENDENCY_NAME is now active ..."

    echo "---> Starting the Slurm REST Daemon (slurmrestd) ..."
    exec sudo -u slurmrestd slurmrestd -vvvvv 0.0.0.0:6820
fi

if [ "$1" = "slurmd" ]
then
    # add compute node config
    if ! grep -q "NodeName=$(hostname)" /etc/slurm/slurm.conf;
    then
        echo "---> Adding compute node configuration to /etc/slurm/slurm.conf ..."
        slurmd -C | head -n 1 >> /etc/slurm/slurm.conf
    fi

    # get cluster info with hostname
    CLUSTER_NAME=$(hostname | sed 's/^[^-]*-//' | grep "cluster")
    if [ -z "$CLUSTER_NAME" ]; then
        DEPDENDENCY_NAME="slurmctld"
    else
        DEPDENDENCY_NAME="slurmctld-$CLUSTER_NAME"
    fi

    echo "---> Waiting for $DEPDENDENCY_NAME to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/"$DEPDENDENCY_NAME"/6817
    do
        echo "-- $DEPDENDENCY_NAME is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- $DEPDENDENCY_NAME is now active ..."

    echo "---> Starting the Slurm Node Daemon (slurmd) ..."
    exec slurmd -Dvvv
fi

exec "$@"
