# slurm-container-debian
Slurm cluster with debian image based containers

Refers to [slurm-docker-cluster](https://github.com/giovtorres/slurm-docker-cluster) and [slinky containers](https://github.com/SlinkyProject/containers), then change to Debian image.

## Features
- slurmrestd
  - Add `SYS_ADMIN` capability to avoid `fatal: Unable to unshare System V namespace: Operation not permitted` error.
- Galera cluster replaces original mariaDB
- Use sackd instead of munge
- Support multi-cluster deployment (see `multi-cluster` folder)
  - Not using Galera cluster for DB

## Usage
1. `git clone https://github.com/ExplorerRay/slurm-container-debian.git`
2. `cd slurm-container-debian`
3. `docker buildx bake`
4. `docker compose up -d`

`docker compose down -v` to stop and remove all containers and volumes.

### Multi-cluster
1. Build images
2. `cd multi-cluster`
3. `dd if=/dev/random of=./config/slurm-cluster1/slurm.key bs=1024 count=1`
4. `cp ./config/slurm-cluster1/slurm.key ./config/slurm-cluster2/slurm.key`
5. `docker compose up -d` to start 2 clusters with common DB and slurmDBD

## Notice
* Because cgroup in container is hard to set, so no cgroup is enabled in compute node slurmd.
