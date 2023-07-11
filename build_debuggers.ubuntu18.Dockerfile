# syntax=docker/dockerfile:1.5

ARG debugger_base=ubuntu:18.04
FROM ${debugger_base}

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

ARG parallelism=3
ARG tools_prefix=/opt/debug_tools

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

#--------
# gdb

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        apt-transport-https \
        software-properties-common \
        coreutils \
        python3-pexpect \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y \
        gdb \
        gdbserver \
    && \
    rm -rf /tmp/*

#--------
# rr

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        python3-urllib3 \
        binutils \
        wget \
    && \
    rm -rf /tmp/*

ARG rr_version="5.6.0"

RUN wget "https://github.com/rr-debugger/rr/releases/download/${rr_version}/rr-${rr_version}-Linux-x86_64.deb" && \
    dpkg -i "rr-${rr_version}-Linux-x86_64.deb" && \
    rm -rf /tmp/*

#--------
# valgrind

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        texinfo \
        libncurses5-dev \
        pkg-config \
        g++ \
        g++-multilib \
        make \
        python-dev \
        manpages-dev \
        ccache \
    && \
    rm -rf /tmp/*

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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb https://apt.llvm.org/bionic/ llvm-toolchain-bionic-${lldb_version} main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y \
        lldb-${lldb_version} \
    && \
    rm -rf /tmp/*

#--------
# xmlrunner

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        python3-pip \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    pip3 install xmlrunner

#--------
# utils

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        tmux \
        vim \
        nano \
        tig \
        iproute2 \
    && \
    rm -rf /tmp/*
