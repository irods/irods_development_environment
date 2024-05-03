# syntax=docker/dockerfile:1.5

ARG debugger_base=almalinux:8
FROM ${debugger_base}

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

ARG parallelism=3
ARG tools_prefix=/opt/debug_tools

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

#--------
# valgrind, gdb

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y gcc-toolset-11 && \
    echo "#!/bin/sh" > /etc/profile.d/gcc-toolset-11.sh && \
    echo "" >> /etc/profile.d/gcc-toolset-11.sh && \
    echo ". /opt/rh/gcc-toolset-11/enable" >> /etc/profile.d/gcc-toolset-11.sh && \
    rm -rf /tmp/*

#--------
# lldb

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y lldb && \
    rm -rf /tmp/*

#--------
# rr

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        python3-urllib3 \
        binutils \
        epel-release \
    && \
    rm -rf /tmp/*

ARG rr_version="5.7.0"

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y "https://github.com/rr-debugger/rr/releases/download/${rr_version}/rr-${rr_version}-Linux-x86_64.rpm" && \
    rm -rf /tmp/*

#--------
# xmlrunner

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
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

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        sudo \
        nano \
        vim-enhanced \
        tmux \
        lsof \
        which \
        file \
        iproute \
    && \
    rm -rf /tmp/*
