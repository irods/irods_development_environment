ARG  debugger_base
FROM ${debugger_base}

SHELL [ "/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

ARG parallelism=3
ARG tools_prefix=/opt/debug_tools

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

#--------
# gdb

RUN apt-get update && \
    apt-get install -y \
        texinfo \
        libncurses5-dev \
        g++ \
        wget \
        make \
        python-dev \
    && \
    apt-get remove -y python3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

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
# rr

ARG rr_commit="4513b23c8092097dc42c73f3cbaf4cfaebd04efe"

RUN apt-get update && \
    apt-get install -y \
        ccache \
        cmake \
        g++-multilib \
        gdb \
        pkg-config \
        coreutils \
        python3-pexpect \
        manpages-dev \
        git \
        ninja-build \
        capnproto \
        libcapnp-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN git clone http://github.com/mozilla/rr && \
    cd rr && \
    { [ -z "${rr_commit}" ] || git checkout "${rr_commit}"; } && \
    mkdir ../obj && cd ../obj && \
    export CCACHE_DISABLE=1 && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=${tools_prefix} ../rr && \
    make -j${parallelism} && \
    make install && \
    cd .. && \
    rm -rf obj rr

#--------
# valgrind

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

RUN apt-get update && \
    apt-get install -y \
        tmux \
        vim \
        nano \
        tig \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
