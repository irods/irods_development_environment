#
# iRODS Common
#
FROM ubuntu:18.04 as irods_common

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update && \
  apt-get install -y \
    apt-transport-https \
    wget \
    lsb-release \
    sudo \
    gnupg \
    python \
    python-psutil \
    python-requests \
    python-jsonschema \
    python3 \
    python3-distro \
    python3-psutil \
    python3-jsonschema \
    python3-requests \
    libssl-dev \
    super \
    lsof \
    postgresql \
    odbc-postgresql \
    libjson-perl \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list && \
    wget -qO - https://core-dev.irods.org/irods-core-dev-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://core-dev.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods-core-dev.list

RUN \
  apt-get update && \
  apt-get install -y \
    'irods-externals*' \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

#
# iRODS Packages Builder Base Image
#
FROM irods_common as irods_package_builder_base

# Install iRODS dependencies.
RUN \
  apt-get update && \
  apt-get install -y \
    git \
    ninja-build \
    libpam0g-dev \
    unixodbc-dev \
    libkrb5-dev \
    libfuse-dev \
    libcurl4-gnutls-dev \
    libbz2-dev \
    libxml2-dev \
    zlib1g-dev \
    python-dev \
    make \
    gcc \
    help2man \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

#
# iRODS Packages Builder Image
#
FROM irods_package_builder_base as irods_package_builder

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH ${cmake_path}:$PATH

ARG clang_path="/opt/irods-externals/clang6.0-0/bin"
ENV PATH ${clang_path}:$PATH

ADD build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]


# How to use:
# ./build_image.sh
# docker run --rm -v /host/path/to/irods_source:/irods_source -v /host/path/to/irods_build:/irods_build -v /host/path/to/icommands_source:/icommands_source -v /host/path/to/icommands_build:/icommands_build -v /host/path/to/irods_packages:/irods_packages irods-core-builder

