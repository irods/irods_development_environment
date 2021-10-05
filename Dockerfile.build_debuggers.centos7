ARG debugger_base=centos:7
FROM ${debugger_base}

SHELL [ "/usr/bin/bash", "-c" ]

ARG parallelism=3
ARG tools_prefix=/opt/debug_tools

RUN mkdir -p  ${tools_prefix}

WORKDIR /tmp

#--------
# TODO: Figure out what section these go in

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    epel-release \
    sudo \
    wget \
    gcc-c++ \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
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
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    python3-pip \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN pip3 --no-cache-dir install pexpect

#--------
# rr

ARG rr_commit="4513b23c8092097dc42c73f3cbaf4cfaebd04efe"

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    capnproto \
    capnproto-devel \
    capnproto-libs \
    ninja-build \
    make \
    git \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    irods-externals-clang-runtime6.0-0 \
    irods-externals-clang6.0-0 \
    irods-externals-cmake3.11.4-0 \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN git clone http://github.com/mozilla/rr && \
    cd rr && \
    { [ -z "${rr_commit}" ] || git checkout "${rr_commit}"; } && \
    mkdir ../obj && cd ../obj && \
    export \
      LD_LIBRARY_PATH=/opt/irods-externals/clang-runtime6.0-0/lib \
      LD_RUN_PATH=/opt/irods-externals/clang-runtime6.0-0/lib \
      CC=/opt/irods-externals/clang6.0-0/bin/clang \
      CXX="/opt/irods-externals/clang6.0-0/bin/clang++ -stdlib=libc++" \
      CCACHE_DISABLE=1 \
    && \
    /opt/irods-externals/cmake3.11.4-0/bin/cmake \
      -DCMAKE_INSTALL_PREFIX:PATH="${tools_prefix}" \
      ../rr \
    && \
    /opt/irods-externals/cmake3.11.4-0/bin/cmake --build . --target install -- -j${parallelism}

#--------
# gdb

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    texinfo \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  wget http://ftp.gnu.org/gnu/gdb/gdb-8.3.1.tar.gz \
    && tar xzf gdb*.tar.gz \
    && cd gdb*/ \
    && export CCACHE_DISABLE=1 \
    && ./configure --prefix=${tools_prefix} --with-python --with-curses --enable-tui \
    && make -j${parallelism} \
    && make install \
    && cd .. \
    && rm -rf gdb*.tar.gz gdb*/

#--------
# valgrind

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
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

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    nano \
    vim-enhanced \
    tmux \
    tig \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*
