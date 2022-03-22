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
    python3 \
    python3-pip \
    python-setuptools \
    python3-setuptools \
    sudo \
    wget \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/*

ARG python_version="python3"
ENV python=${python_version}

ARG python_ci_utilities_url="https://github.com/irods/irods_python_ci_utilities"
ENV ci_url=${python_ci_utilities_url}

ARG python_ci_utilities_branch="main"
ENV ci_branch=${python_ci_utilities_branch}

RUN \
  git clone ${ci_url} -b ${ci_branch} && \
  ${python} -m pip install /irods_python_ci_utilities && \
  rm -r /irods_python_ci_utilities

ENV file_extension="deb"
ENV package_manager="apt"

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
