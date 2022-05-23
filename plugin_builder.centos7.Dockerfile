FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN yum update -y || [ "$?" -eq 100 ] && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN yum install -y \
        epel-release \
        sudo \
        wget \
        git \
        rpm-build \
        gcc-c++ \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

# python 2 and 3 must be installed separately because yum will ignore/discard python2
RUN yum install -y \
        python3 \
        python3-devel \
        python3-pip \
    && \
    yum install -y \
        python \
        python-devel \
        python-pip \
    && \
    pip --no-cache-dir install --upgrade 'pip<21.0' && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

ENV python="python3"

# see https://pip.pypa.io/en/stable/topics/vcs-support/
ARG python_ci_utilities_vcs="git+https://github.com/irods/irods_python_ci_utilities.git@main"

RUN "${python}" -m pip --no-cache-dir install "${python_ci_utilities_vcs}"

ENV file_extension="rpm"
ENV package_manager="yum"

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
