# slurm-container-debian
Slurm cluster with debian image based containers

Refers to https://github.com/giovtorres/slurm-docker-cluster and change to Debian image.

**Compute node doesn't work now due to some cgroup issues.**

## Usage
1. `git clone https://github.com/ExplorerRay/slurm-container-debian.git`
2. `cd slurm-container-debian`
3. `docker buildx bake --no-cache`
4. `docker compose up -d`

`docker compose down -v` to stop and remove all containers and volumes.
