FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    git \
    python \
    python-pip \
    python-setuptools \
    wget \
    sudo \
    lsb-release \
    gdebi \
    apt-utils \
    gnupg \
    libxml2-dev \
    apt-transport-https \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

RUN \
  git clone https://github.com/irods/irods_python_ci_utilities && \
  pip install /irods_python_ci_utilities && \
  rm -r /irods_python_ci_utilities

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
