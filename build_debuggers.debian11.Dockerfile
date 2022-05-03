ARG debugger_base=debian:11
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
        gdb \
        gdbserver \
    && \
    apt-get remove -y python3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

#--------
# rr

RUN apt-get update && \
    apt-get install -y \
        python3-urllib3 \
        binutils \
        wget \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ARG rr_version="5.5.0"

RUN wget "https://github.com/rr-debugger/rr/releases/download/${rr_version}/rr-${rr_version}-Linux-x86_64.deb" && \
    dpkg -i "rr-${rr_version}-Linux-x86_64.deb" && \
    rm -rf /tmp/*

#--------
# valgrind

RUN apt-get update && \
    apt-get install -y \
        valgrind \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

#--------
# lldb

RUN apt-get update && \
    apt-get install -y \
        lldb \
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
        coreutils \
        python3-pexpect \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
