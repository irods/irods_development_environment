# syntax=docker/dockerfile:1.5
#
# iRODS Runner
#
ARG runner_base=almalinux:8
FROM ${runner_base} as irods-runner

SHELL [ "/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        epel-release \
        sudo \
        wget \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        rsyslog \
        python3 \
        python3-distro \
        python3-jsonschema \
        python3-psutil \
        python3-pyodbc \
        python3-requests \
        openssl \
        lsof \
        postgresql-server \
        unixODBC \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        dnf-plugin-config-manager \
    && \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    dnf config-manager -y --add-repo https://packages.irods.org/renci-irods.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    dnf config-manager -y --add-repo https://core-dev.irods.org/renci-irods-core-dev.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods-core-dev && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        'irods-externals*' \
    && \
    rm -rf /tmp/*

COPY ICAT.sql /
COPY --chmod=755 keep_alive.sh /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
