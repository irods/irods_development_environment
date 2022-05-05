#
# iRODS Runner
#
ARG runner_base=almalinux:8
FROM ${runner_base} as irods-runner

SHELL [ "/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN dnf update -y || [ "$?" -eq 100 ] && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        epel-release \
        sudo \
        wget \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
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
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        dnf-plugin-config-manager \
    && \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    dnf config-manager -y --add-repo https://packages.irods.org/renci-irods.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    dnf config-manager -y --add-repo https://core-dev.irods.org/renci-irods-core-dev.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods-core-dev && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        'irods-externals*' \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

ADD ICAT.sql /
ADD keep_alive.sh /keep_alive.sh
RUN chmod +x /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
