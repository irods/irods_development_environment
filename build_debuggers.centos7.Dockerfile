ARG debugger_base=centos:7
FROM ${debugger_base}

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN yum update -y || [ "$?" -eq 100 ] && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

ARG parallelism=3
ARG tools_prefix=/opt/debug_tools

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

RUN yum install -y \
        epel-release \
        centos-release-scl \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

#--------
# TODO: Figure out what section these go in

RUN yum install -y \
        sudo \
        wget \
        gcc-c++ \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN yum install -y \
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
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN yum install -y \
        python3-pip \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN pip3 --no-cache-dir install pexpect

#--------
# valgrind, gdb

RUN yum install -y devtoolset-11 && \
    echo "#!/bin/sh" > /etc/profile.d/devtoolset-11.sh && \
    echo "" >> /etc/profile.d/devtoolset-11.sh && \
    echo ". /opt/rh/devtoolset-11/enable" >> /etc/profile.d/devtoolset-11.sh && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

#--------
# rr

RUN yum install -y \
        python36-urllib3 \
        binutils \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

ARG rr_version="5.5.0"

RUN yum localinstall -y "https://github.com/rr-debugger/rr/releases/download/${rr_version}/rr-${rr_version}-Linux-x86_64.rpm" && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

#--------
# utils

RUN yum install -y \
        nano \
        vim-enhanced \
        tmux \
        tig \
        lsof \
        which \
        less \
        file \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*
