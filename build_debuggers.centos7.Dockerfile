# syntax=docker/dockerfile:1.5

ARG debugger_base=centos:7
FROM ${debugger_base}

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    sed -i \
        -e 's/mirror.centos.org/vault.centos.org/g' \
        -e 's/^#.*baseurl=http/baseurl=http/g' \
        -e 's/^mirrorlist=http/#mirrorlist=http/g' \
        /etc/yum.repos.d/*.repo && \
    yum update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

ARG parallelism=3
ARG tools_prefix=/opt/debug_tools

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        epel-release \
        centos-release-scl \
    && \
    sed -i \
        -e 's/mirror.centos.org/vault.centos.org/g' \
        -e 's/^#.*baseurl=http/baseurl=http/g' \
        -e 's/^mirrorlist=http/#mirrorlist=http/g' \
        /etc/yum.repos.d/*.repo && \
    rm -rf /tmp/*

#--------
# TODO: Figure out what section these go in

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        sudo \
        wget \
        gcc-c++ \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        python3 \
        ccache \
        cmake \
        make \
        gcc \
        gcc-c++ \
        gdb \
        libgcc \
        libgcc.i686 \
        glibc-devel \
        glibc-devel.i686 \
        libstdc++-devel \
        libstdc++-devel.i686 \
        python-devel \
        ncurses-devel \
        which \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        python3-pip \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    pip3 install pexpect

#--------
# lldb

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y llvm-toolset-7 && \
    echo "#!/bin/sh" > /etc/profile.d/llvm-toolset-7.sh && \
    echo "" >> /etc/profile.d/llvm-toolset-7.sh && \
    echo ". /opt/rh/llvm-toolset-7/enable" >> /etc/profile.d/llvm-toolset-7.sh && \
    rm -rf /tmp/*

ENV PATH=/opt/rh/llvm-toolset-7/root/usr/bin:$PATH

#--------
# valgrind, gdb

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y devtoolset-10 && \
    echo "#!/bin/sh" > /etc/profile.d/devtoolset-10.sh && \
    echo "" >> /etc/profile.d/devtoolset-10.sh && \
    echo ". /opt/rh/devtoolset-10/enable" >> /etc/profile.d/devtoolset-10.sh && \
    rm -rf /tmp/*

ENV PATH=/opt/rh/devtoolset-10/root/usr/bin:$PATH

#--------
# rr

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        python36-urllib3 \
        binutils \
        epel-release \
    && \
    rm -rf /tmp/*

ARG rr_version="5.6.0"

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum localinstall -y "https://github.com/rr-debugger/rr/releases/download/${rr_version}/rr-${rr_version}-Linux-x86_64.rpm" && \
    rm -rf /tmp/*

#--------
# xmlrunner

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        python3-pip \
        python3-lxml \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    python3 -m pip install \
        unittest-xml-reporting \
    && \
    rm -rf /tmp/*

#--------
# utils

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        nano \
        vim-enhanced \
        tmux \
        tig \
        lsof \
        which \
        less \
        file \
        iproute \
    && \
    rm -rf /tmp/*
