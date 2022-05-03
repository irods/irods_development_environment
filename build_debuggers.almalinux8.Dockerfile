ARG debugger_base=almalinux:8

FROM ${debugger_base}

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN dnf update -y || [ "$?" -eq 100 ] && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

ARG parallelism=3
ARG tools_prefix=/opt/debug_tools

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

#--------
# valgrind, gdb

RUN dnf install -y gcc-toolset-11 && \
    echo "#!/bin/sh" > /etc/profile.d/gcc-toolset-11.sh && \
    echo "" >> /etc/profile.d/gcc-toolset-11.sh && \
    echo ". /opt/rh/gcc-toolset-11/enable" >> /etc/profile.d/gcc-toolset-11.sh && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

#--------
# lldb

RUN dnf install -y lldb && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

#--------
# rr

RUN dnf install -y \
        python3-urllib3 \
        binutils \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

ARG rr_version="5.5.0"

RUN dnf install -y "https://github.com/rr-debugger/rr/releases/download/${rr_version}/rr-${rr_version}-Linux-x86_64.rpm" && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

#--------
# utils

RUN dnf install -y \
        sudo \
        nano \
        vim-enhanced \
        tmux \
        lsof \
        which \
        file \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*
