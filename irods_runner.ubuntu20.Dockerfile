#
# iRODS Runner
#
ARG runner_base=ubuntu:20.04
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
        python3 \
        python3-psutil \
        python3-requests \
        python3-jsonschema \
        python3-pyodbc \
        python3-distro \
        libssl1.1 \
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

RUN apt-get update && \
    apt-get install -y \
        'irods-externals*' \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ADD ICAT.sql /
ADD keep_alive.sh /keep_alive.sh
RUN chmod +x /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
