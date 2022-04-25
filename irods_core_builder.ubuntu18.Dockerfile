FROM ubuntu:18.04

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
        gcc \
        git \
        gnupg \
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
        python-jsonschema \
        python-psutil \
        python-requests \
        python3 \
        python3-distro \
        python3-jsonschema \
        python3-psutil \
        python3-requests \
        sudo \
        super \
        unixodbc-dev \
        wget \
        zlib1g-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN apt-get update && \
    apt-get install -y \
        cmake \
        python3-pip \
        libspdlog-dev \
    && \
    python3 -m pip --no-cache-dir install \
        lief \
            --global-option="--lief-no-cache" \
            --global-option="--ninja" \
            --global-option="--lief-no-pe" \
            --global-option="--lief-no-macho" \
            --global-option="--lief-no-android" \
            --global-option="--lief-no-art" \
            --global-option="--lief-no-vdex" \
            --global-option="--lief-no-oat" \
            --global-option="--lief-no-dex" \
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

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ARG clang_path="/opt/irods-externals/clang6.0-0/bin"
ENV PATH=${clang_path}:$PATH

ENV file_extension="deb"
ENV package_manager="apt-get"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
