FROM almalinux:8

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN dnf update -y || [ "$?" -eq 100 ] && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

RUN dnf install -y \
        epel-release \
        sudo \
        wget \
        git \
        rpm-build \
        gcc-c++ \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

RUN dnf install -y \
        python3 \
        python3-devel \
        python3-pip \
    && \
    python3 -m pip --no-cache-dir install --upgrade 'pip<21.0' && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

# TODO: python3 is the only option at this time, so we don't really need this
ENV python="python3"

# see https://pip.pypa.io/en/stable/topics/vcs-support/
ARG python_ci_utilities_vcs="git+https://github.com/irods/irods_python_ci_utilities.git@main"

RUN "${python}" -m pip --no-cache-dir install "${python_ci_utilities_vcs}"

ENV file_extension="rpm"
ENV package_manager="dnf"

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
