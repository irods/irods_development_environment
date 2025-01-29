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
        python3 \
        python3-distro \
        python3-jsonschema \
        python3-psutil \
        python3-pyodbc \
        python3-requests \
        openssl \
        procps \
        lsof \
        postgresql-server \
        unixODBC \
    && \
    rm -rf /tmp/*

# install and configure rsyslog
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        rsyslog \
    && \
    sed -i -E \
        -e 's/SysSock\.Use\s*=\s*"?off"?/SysSock.Use="on"/' \
        /etc/rsyslog.conf \
    && \
    rm -rf /tmp/*
COPY irods.rsyslog /etc/rsyslog.d/00-irods.conf
COPY irods.logrotate /etc/logrotate.d/irods

# irodsauthuser required for some tests
# UID and GID ranges picked to hopefully not overlap with anything
RUN useradd \
        --key UID_MIN=40000 \
        --key UID_MAX=50000 \
        --key GID_MIN=40000 \
        --key GID_MAX=50000 \
        --create-home \
        --shell /bin/bash \
        irodsauthuser && \
    echo 'irodsauthuser:;=iamnotasecret' | chpasswd

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

# Disable unwanted systemd units, set default target
RUN find /etc/systemd/system \
        /lib/systemd/system \
        \( -path '*.wants/*' -or -path '*.requires/*' -or -path '*.upholds/*' \) \
        -not -name '*journald*' \
        -not -name '*dbus*' \
        -not -name '*rsyslog*' \
        -not -name '*systemd-journal*' \
        -not -name '*systemd-tmpfiles*' \
        -not -name '*systemd-user-sessions*' \
        -not -name '*systemd-sysext*' \
        -delete && \
    rm -rf /usr/lib/systemd/system/timers.target.wants/systemd-tmpfiles-clean.timer && \
    ln -sf /usr/lib/systemd/system/multi-user.target /etc/systemd/system/default.target
# Note that the patterns passed to find above are being *excluded* from the delete command

COPY ICAT.sql /
COPY --chmod=755 keep_alive.sh /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
