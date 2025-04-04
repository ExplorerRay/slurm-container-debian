#!/bin/bash
set -e

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    sudo -u munge /usr/sbin/munged

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

    exec sudo -u slurm /usr/local/sbin/slurmdbd -Dvvv
fi

if [ "$1" = "slurmctld" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    sudo -u munge /usr/sbin/munged

    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."

    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."

    exec sudo -u slurm /usr/local/sbin/slurmctld -i -Dvvv
fi

if [ "$1" = "slurmrestd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    sudo -u munge /usr/sbin/munged

    echo "---> Waiting for slurmctld to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    echo "---> Starting the Slurm REST Daemon (slurmrestd) ..."
    exec sudo -u slurmrestd /usr/local/sbin/slurmrestd -vvvvv 0.0.0.0:6820
fi

if [ "$1" = "slurmd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    sudo -u munge /usr/sbin/munged

    # add compute node config
    if ! grep -q "NodeName=$(hostname)" /etc/slurm/slurm.conf;
    then
        echo "---> Adding compute node configuration to /etc/slurm/slurm.conf ..."
        /usr/local/sbin/slurmd -C | head -n 1 >> /etc/slurm/slurm.conf
    fi

    echo "---> Waiting for slurmctld to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    echo "---> Starting the Slurm Node Daemon (slurmd) ..."
    exec /usr/local/sbin/slurmd -Dvvv
fi

exec "$@"
