ARG debugger_base=ubuntu:18.04
FROM ${debugger_base}

SHELL [ "/bin/bash", "-c" ]

ENV DEBIAN_FRONTEND=noninteractive

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

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

#--------
# gdb

RUN apt-get update && \
    apt-get install -y \
        texinfo \
        libncurses5-dev \
        pkg-config \
        g++ \
        g++-multilib \
        wget \
        make \
        python-dev \
        manpages-dev \
        ccache \
        coreutils \
        python3-pexpect \
    && \
    apt-get remove -y python3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ARG gdb_version="8.3.1"

RUN wget "http://ftp.gnu.org/gnu/gdb/gdb-${gdb_version}.tar.gz" && \
    tar xzf "gdb-${gdb_version}.tar.gz" && \
    cd "gdb-${gdb_version}" && \
    export CCACHE_DISABLE=1 && \
    ./configure --prefix=${tools_prefix} --with-python --with-curses --enable-tui && \
    make -j${parallelism} && \
    make install && \
    cd .. && \
    rm -rf "gdb-${gdb_version}.tar.gz" "gdb-${gdb_version}"

#--------
# rr

RUN apt-get update && \
    apt-get install -y \
        python3-urllib3 \
        binutils \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ARG rr_version="5.5.0"

RUN wget "https://github.com/rr-debugger/rr/releases/download/${rr_version}/rr-${rr_version}-Linux-x86_64.deb" && \
    dpkg -i "rr-${rr_version}-Linux-x86_64.deb" && \
    rm -rf /tmp/*

#--------
# valgrind

ARG valgrind_version="3.15.0"

RUN wget "https://sourceware.org/pub/valgrind/valgrind-${valgrind_version}.tar.bz2" && \
    tar xjf "valgrind-${valgrind_version}.tar.bz2" && \
    cd "valgrind-${valgrind_version}" && \
    export CCACHE_DISABLE=1 && \
    ./configure --prefix=${tools_prefix} && \
    make -j${parallelism} install && \
    cd .. && \
    rm -rf "valgrind-${valgrind_version}.tar.bz2" "valgrind-${valgrind_version}"

#--------
# lldb

ARG lldb_version="14"

RUN wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb https://apt.llvm.org/bionic/ llvm-toolchain-bionic-${lldb_version} main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y \
        lldb-${lldb_version} \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

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
