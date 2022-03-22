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

RUN git clone https://github.com/irods/irods_python_ci_utilities && \
    pip --no-cache-dir install -e /irods_python_ci_utilities

ENV file_extension="deb"
ENV package_manager="apt"

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
