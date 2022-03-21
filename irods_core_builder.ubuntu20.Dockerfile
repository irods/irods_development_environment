FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        g++-10 \
        gcc \
        gcc-10 \
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
        python-dev \
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

# TODO: Uncomment this section when externals packages are available for this platform
#RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
#    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list && \
#    wget -qO - https://core-dev.irods.org/irods-core-dev-signing-key.asc | apt-key add - && \
#    echo "deb [arch=amd64] https://core-dev.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods-core-dev.list

#RUN apt-get update && \
#    apt-get install -y \
#        'irods-externals*' \
#    && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/*

RUN update-alternatives --install /usr/local/bin/gcc gcc /usr/bin/gcc-10 1 && \
    update-alternatives --install /usr/local/bin/g++ g++ /usr/bin/g++-10 1 && \
    hash -r

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ENV file_extension="deb"
ENV package_manager="apt"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
