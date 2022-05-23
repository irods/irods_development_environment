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
    pip --no-cache-dir install --upgrade 'pip<21.0' && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ENV python="python2"

# see https://pip.pypa.io/en/stable/topics/vcs-support/
ARG python_ci_utilities_vcs="git+https://github.com/irods/irods_python_ci_utilities.git@main"

RUN "${python}" -m pip --no-cache-dir install "${python_ci_utilities_vcs}"

ENV file_extension="deb"
ENV package_manager="apt-get"

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
