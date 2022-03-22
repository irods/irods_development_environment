#
# iRODS Runner
#
ARG runner_base=ubuntu:18.04
FROM ${runner_base} as irods-runner

SHELL [ "/bin/bash", "-c" ]

ENV DEBIAN_FRONTEND=noninteractive

# Make sure we're starting with an up-to-date image
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        wget \
        lsb-release \
        sudo \
        gnupg \
        rsyslog \
        python \
        python-psutil \
        python-requests \
        python-jsonschema \
        python-distro \
        python3 \
        python3-psutil \
        python3-requests \
        python3-jsonschema \
        python3-pyodbc \
        python3-distro \
        libssl-dev \
        super \
        lsof \
        postgresql \
        odbc-postgresql \
        libjson-perl \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN apt-get update && \
    apt-get install -y \
        git \
        vim \
        nano \
        rsyslog \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list && \
    wget -qO - https://core-dev.irods.org/irods-core-dev-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://core-dev.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods-core-dev.list

ARG irods_version="4.2.8"
RUN apt-get update && \
    apt-get install -y \
        'irods-externals*' \
        irods-runtime=${irods_version} \
        irods-icommands=${irods_version} \
        irods-server=${irods_version} \
        irods-database-plugin-postgres=${irods_version} \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ADD ICAT.sql /
ADD keep_alive.sh /keep_alive.sh
RUN chmod +x /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
