#
# iRODS Runner
#
ARG runner_base=centos:7
FROM ${runner_base} as irods-runner

SHELL [ "/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN yum update -y || [ "$?" -eq 100 ] && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN yum install -y \
        epel-release \
        sudo \
        wget \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

# python 2 and 3 must be installed separately because yum will ignore/discard python2
RUN yum install -y \
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
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

# For Python3 modules not available as packages:
# python3-devel must be installed because pyodbc requires building
RUN yum install -y \
        gcc-c++ \
        make \
        python3-devel \
        python3-pip \
    && \
    python3 -m pip --no-cache-dir install \
        pyodbc \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
    wget -qO - https://packages.irods.org/renci-irods.yum.repo | sudo tee /etc/yum.repos.d/renci-irods.yum.repo && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | sudo tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

ARG irods_version="4.2.0"
RUN yum install -y \
        'irods-externals*' \
        irods-runtime-${irods_version} \
        irods-icommands-${irods_version} \
        irods-server-${irods_version} \
        irods-database-plugin-postgres-${irods_version} \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

ADD ICAT.sql /
ADD keep_alive.sh /keep_alive.sh
RUN chmod +x /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
