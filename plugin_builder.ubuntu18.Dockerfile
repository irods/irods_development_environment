FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    apt-utils \
    build-essential \
    git \
    gnupg \
    libxml2-dev \
    lsb-release \
    python \
    python-pip \
    python-setuptools \
    sudo \
    wget \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

RUN \
  git clone https://github.com/irods/irods_python_ci_utilities && \
  pip install -e /irods_python_ci_utilities

ENV file_extension="deb"
ENV package_manager="apt"

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
