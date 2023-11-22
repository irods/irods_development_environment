# syntax=docker/dockerfile:1.5
FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        epel-release \
        sudo \
        wget \
        git \
        rpm-build \
        gcc-c++ \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        python3 \
        python3-devel \
        python3-pip \
        python36-distro \
        python36-packaging \
    && \
    rm -rf /tmp/*

ENV python="python3"

# see https://pip.pypa.io/en/stable/topics/vcs-support/
ARG python_ci_utilities_vcs="git+https://github.com/irods/irods_python_ci_utilities.git@main"

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    "${python}" -m pip install "${python_ci_utilities_vcs}" && \
    rm -rf /tmp/*

ENV file_extension="rpm"
ENV package_manager="yum"

COPY build_and_copy_plugin_packages_to_dir.sh /
COPY --chmod=755 build_and_copy_plugin_packages_to_dir.sh /
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
