# slurm-container-debian
Slurm cluster with debian image based containers

Refers to https://github.com/giovtorres/slurm-docker-cluster and change to Debian image.

## Extra features
- slurmrestd
- Galera replaces original mariaDB

## Usage
1. `git clone https://github.com/ExplorerRay/slurm-container-debian.git`
2. `cd slurm-container-debian`
3. `docker buildx bake`
4. `docker compose up -d`

`docker compose down -v` to stop and remove all containers and volumes.

## Notice
* Because cgroup in container is hard to set, so no cgroup is enabled in compute node slurmd.
