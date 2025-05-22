# syntax=docker/dockerfile:1.5

ARG debugger_base=rockylinux/rockylinux:9
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
# valgrind

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y valgrind && \
    rm -rf /tmp/*

#--------
# gdb

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        gdb \
        gdb-gdbserver \
    && \
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

# The rr package from github is built for EL8.
# Due to package dependencies, it can't be installed on EL9.
# The package from Fedora 38 is very close. We can use it if we update libstdc++ and glibc.

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/g/glibc-2.37-19.fc38.x86_64.rpm" \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/g/glibc-2.37-19.fc38.i686.rpm" \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/g/glibc-common-2.37-19.fc38.x86_64.rpm" \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/g/glibc-minimal-langpack-2.37-19.fc38.x86_64.rpm" \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/g/glibc-devel-2.37-19.fc38.x86_64.rpm" \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/g/glibc-headers-x86-2.37-19.fc38.noarch.rpm" \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/l/libstdc++-13.2.1-7.fc38.x86_64.rpm" \
    && \
    dnf install -y \
        "https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/38/Everything/x86_64/Packages/r/rr-5.7.0-9.fc38.x86_64.rpm" \
    && \
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
