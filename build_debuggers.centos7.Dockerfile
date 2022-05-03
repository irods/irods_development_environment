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

#--------
# TODO: Figure out what section these go in

RUN yum install -y \
        epel-release \
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
# gdb

RUN yum install -y \
        texinfo \
        make \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN wget http://ftp.gnu.org/gnu/gdb/gdb-8.3.1.tar.gz && \
    tar xzf gdb*.tar.gz && \
    cd gdb*/ && \
    export CCACHE_DISABLE=1 && \
    ./configure --prefix=${tools_prefix} --with-python --with-curses --enable-tui && \
    make -j${parallelism} && \
    make install && \
    cd .. && \
    rm -rf gdb*.tar.gz gdb*/

#--------
# valgrind

RUN yum install -y \
        bzip2 \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN wget https://sourceware.org/pub/valgrind/valgrind-3.15.0.tar.bz2 && \
    tar xjf valgrind*tar.bz2 && \
    cd valgrind*/ && \
    export CCACHE_DISABLE=1 && \
    ./configure --prefix=${tools_prefix} && \
    make -j${parallelism} install && \
    cd .. && \
    rm -rf valgrind*tar.bz2 valgrind*/

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
