# syntax=docker/dockerfile:1.5
#
# iRODS Runner
#
ARG runner_base=centos:7
FROM ${runner_base} as irods-runner

SHELL [ "/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        epel-release \
        sudo \
        wget \
    && \
    rm -rf /tmp/*

# python 2 and 3 must be installed separately because yum will ignore/discard python2
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        rsyslog \
        openssl-devel \
        lsof \
        postgresql-server \
        unixODBC-devel \
    && \
    yum install -y \
        python \
        python-distro \
        python2-jsonschema \
        python2-psutil \
        python-requests \
        pyodbc \
    && \
    yum install -y \
        python36 \
        python3-distro \
        python36-jsonschema \
        python36-psutil \
        python36-requests \
    && \
    rm -rf /tmp/*

# For Python3 modules not available as packages:
# python3-devel must be installed because pyodbc requires building
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    yum install -y \
        gcc-c++ \
        make \
        python3-devel \
        python3-pip \
    && \
    python3 -m pip install \
        pyodbc \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    wget -qO - https://packages.irods.org/renci-irods.yum.repo | sudo tee /etc/yum.repos.d/renci-irods.yum.repo && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | sudo tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    rm -rf /tmp/*

ARG irods_version="4.2.0"
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        'irods-externals*' \
        irods-runtime-${irods_version} \
        irods-icommands-${irods_version} \
        irods-server-${irods_version} \
        irods-database-plugin-postgres-${irods_version} \
    && \
    rm -rf /tmp/*

COPY ICAT.sql /
COPY --chmod=755 keep_alive.sh /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
