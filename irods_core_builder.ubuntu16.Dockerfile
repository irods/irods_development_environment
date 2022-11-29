FROM ubuntu:16.04

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
        ccache \
        gcc \
        git \
        help2man \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libfuse-dev \
        libjson-perl \
        libkrb5-dev \
        libpam0g-dev \
        libssl-dev \
        libxml2-dev \
        lsb-release \
        lsof \
        make \
        ninja-build \
        odbc-postgresql \
        postgresql \
        python \
        python-dev \
        python-pip \
        python-jsonschema \
        python-packaging \
        python-psutil \
        python-pyodbc \
        python-requests \
        python3 \
        python3-dev \
        python3-pip \
        python3-jsonschema \
        python3-packaging \
        python3-psutil \
        python3-pyodbc \
        python3-requests \
        sudo \
        super \
        unixodbc-dev \
        wget \
        zlib1g-dev \
    && \
    pip --no-cache-dir install --upgrade 'pip<21.0' && \
    pip --no-cache-dir install \
        distro \
    && \
    pip3 --no-cache-dir install \
        distro \
        lief==0.10.1 \
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

ARG cmake_path="/opt/irods-externals/cmake3.11.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ARG clang_path="/opt/irods-externals/clang6.0-0/bin"
ENV PATH=${clang_path}:$PATH

ENV file_extension="deb"
ENV package_manager="apt-get"
ENV CCACHE_DIR="/irods_build_cache"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
