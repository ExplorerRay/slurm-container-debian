################################################################################
# GLOBAL ARGUMENTS

ARG SLURM_VERSION=25.05-latest
ARG SLURM_DIR=slurm
ARG PARENT_IMAGE=debian:stable-slim

################################################################################
FROM alpine:latest AS slurm-src

ARG SLURM_VERSION
ARG SLURM_DIR
ARG SLURM_TAR="slurm-${SLURM_VERSION}"

WORKDIR /workspace/

ADD https://download.schedmd.com/slurm/${SLURM_TAR}.tar.bz2 ${SLURM_TAR}.tar.bz2

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOR
# Unpack Slurm Source
set -xeuo pipefail
apk upgrade -q --update-cache
apk add -q tar
mkdir -p ${SLURM_DIR}
tar --strip-components=1 -jxvf ${SLURM_TAR}.tar.bz2 -C ${SLURM_DIR}
rm ${SLURM_TAR}.tar.bz2
EOR

################################################################################
FROM ${PARENT_IMAGE} AS build

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ARG SLURM_DIR
ARG SLURM_VERSION
ENV SLURM_VERSION=${SLURM_VERSION}

USER root
WORKDIR /tmp/

COPY --from=slurm-src /workspace/${SLURM_DIR} ${SLURM_DIR}

# Ref: https://slurm.schedmd.com/quickstart_admin.html#debuild
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOR
# Build Slurm
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y upgrade
apt-get -qq -y install --no-install-recommends \
  build-essential fakeroot devscripts equivs
## Build
mk-build-deps -ir --tool='apt-get -qq -y -o Debug::pkgProblemResolver=yes --no-install-recommends' ${SLURM_DIR}/debian/control
( cd ${SLURM_DIR} && debuild -b -uc -us >/dev/null )
EOR

################################################################################
FROM ${PARENT_IMAGE} AS base

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ARG SLURM_VERSION
ENV SLURM_VERSION=${SLURM_VERSION}

USER root
WORKDIR /tmp/

ARG SLURM_USER=slurm
ARG SLURM_USER_UID=151
ARG SLURM_USER_GID=151

RUN <<EOR
# Create SlurmUser
set -xeuo pipefail
groupadd --system --gid=${SLURM_USER_GID} ${SLURM_USER}
useradd --system --no-log-init --uid=${SLURM_USER_UID} --gid=${SLURM_USER_GID} --shell=/usr/sbin/nologin ${SLURM_USER}
groupadd --system --gid=152 slurmrestd
useradd --system --no-log-init --uid=152 --gid=152 --shell=/usr/sbin/nologin slurmrestd
EOR

RUN <<EOR
# Remove Users
set -xeuo pipefail
for user in $(ls /home/); do
  userdel --remove $user
done
EOR

COPY --from=build /tmp/*.deb /tmp/*.ddeb /tmp/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOR
# Install Dependencies
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y upgrade
apt-get -qq -y install --no-install-recommends \
  sudo mariadb-client
EOR

RUN <<EOR
# Set Slurm key
mkdir -p /etc/slurm/
dd if=/dev/random of=/etc/slurm/slurm.key bs=1024 count=1
chown slurm:slurm /etc/slurm/slurm.key
chmod 600 /etc/slurm/slurm.key
# Create necessary directories
mkdir -p /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmctld \
        /var/run/slurmdbd \
        /var/log/slurm \
        /data
mkdir -m 700 /var/spool/slurmctld
chown -R slurm:slurm /var/*/slurm*
EOR

COPY ./config/slurm/slurm.conf /etc/slurm/
COPY --chown=slurm:slurm --chmod=600 ./config/slurm/slurmdbd.conf /etc/slurm/
COPY ./config/slurm/cgroup.conf /etc/slurm/

COPY ./container/slurm/entrypoint.sh /usr/local/bin/entrypoint.sh

################################################################################
FROM base AS slurmctld-debian

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  socat \
  ./slurm-smd-client_[0-9]*.deb \
  ./slurm-smd-slurmctld_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
rm *.deb
EOR

EXPOSE 6817/tcp
ENTRYPOINT ["entrypoint.sh"]

################################################################################
FROM base AS slurmd-debian

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  gawk socat \
  ./slurm-smd-client_[0-9]*.deb \
  ./slurm-smd-slurmd_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
rm *.deb
# Configure
mkdir -p /var/spool/slurmd/
# cp -v /etc/nsswitch.conf{,.bak}
# sed -i -E "s/^passwd:[[:space:]]+/&slurm /g" /etc/nsswitch.conf
# sed -i -E "s/^group:[[:space:]]+/&slurm /g" /etc/nsswitch.conf
EOR

EXPOSE 6818/tcp
ENTRYPOINT ["entrypoint.sh"]

################################################################################
FROM base AS slurmdbd-debian

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  ./slurm-smd-slurmdbd_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
rm *.deb
EOR

EXPOSE 6819/tcp
ENTRYPOINT ["entrypoint.sh"]

################################################################################
FROM base AS slurmrestd-debian

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  ./slurm-smd-slurmrestd_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
rm *.deb
EOR

EXPOSE 6820/tcp
ENTRYPOINT ["entrypoint.sh"]
