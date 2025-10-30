# slurm-container-debian
Slurm cluster with debian image based containers

Refers to [slurm-docker-cluster](https://github.com/giovtorres/slurm-docker-cluster) and [slinky containers](https://github.com/SlinkyProject/containers), then change to Debian image.

## Features
- slurmrestd
  - Add `SYS_ADMIN` capability to avoid `fatal: Unable to unshare System V namespace: Operation not permitted` error.
- Galera cluster replaces original mariaDB
- Use sackd instead of munge

## Usage
1. `git clone https://github.com/ExplorerRay/slurm-container-debian.git`
2. `cd slurm-container-debian`
3. `docker buildx bake`
4. `docker compose up -d`

`docker compose down -v` to stop and remove all containers and volumes.

## Notice
* Because cgroup in container is hard to set, so no cgroup is enabled in compute node slurmd.
