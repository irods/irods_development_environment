# syntax=docker/dockerfile:1.5

FROM ubuntu:20.04

SHELL [ "/bin/bash", "-c" ]
ENV DEBIAN_FRONTEND=noninteractive

# Re-enable apt caching for RUN --mount
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    rm -rf /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        apt-utils \
        build-essential \
        cmake \
        git \
        gnupg \
        libxml2-dev \
        lsb-release \
        python3 \
        python3-distro \
        python3-packaging \
        python3-pip \
        python3-setuptools \
        sudo \
        wget \
    && \
    rm -rf /tmp/*

ENV python="python3"

# see https://pip.pypa.io/en/stable/topics/vcs-support/
ARG python_ci_utilities_vcs="git+https://github.com/irods/irods_python_ci_utilities.git@main"

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    "${python}" -m pip install "${python_ci_utilities_vcs}" && \
    rm -rf /tmp/*

ENV file_extension="deb"
ENV package_manager="apt-get"

COPY --chmod=755 build_and_copy_plugin_packages_to_dir.sh /
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
