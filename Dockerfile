FROM debian:12-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    git build-essential python3 bash-completion sudo \
    # refers to https://slurm.schedmd.com/quickstart_admin.html#prereqs
    # for auth/munge
    munge libmunge-dev \
    # for PMIx support
    # libpmix-dev \
    # for DBD node accessing DB server
    mariadb-client \
    # for accounting_storage/mysql
    libmariadb-dev \
    # for slurmrestd
    libhttp-parser-dev libjson-c-dev libyaml-dev libjwt-dev \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/apt/lists/*

ARG SLURM_TAG

SHELL ["/bin/bash", "-c"]

RUN git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && ./configure --sysconfdir=/etc/slurm \
    && make install \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r --gid=151 slurm \
    && useradd -r -g slurm --uid=151 slurm \
    && mkdir /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
        /var/log/slurm \
        /data \
        /run/munge \
    && mkdir -m 700 /var/spool/slurmctld \
    && chown -R munge:munge /run/munge \
    && chown -R slurm:slurm /var/*/slurm* \
    && sudo -u munge /usr/sbin/mungekey -f -v

COPY ./config/slurm.conf /etc/slurm/
COPY --chown=slurm:slurm --chmod=600 ./config/slurmdbd.conf /etc/slurm/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["slurmdbd"]
