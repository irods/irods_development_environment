FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    epel-release \
    wget \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    bzip2-devel \
    fuse-devel \
    gcc-c++ \
    git \
    help2man \
    krb5-devel \
    libcurl-devel \
    libjson-perl \
    libxml2-devel \
    lsof \
    make \
    ninja-build \
    openssl \
    openssl-devel \
    pam-devel \
    postgresql-server \
    python \
    rpm-build \
    sudo \
    super \
    unixODBC-devel \
    which \
    zlib-devel \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

# python 2 and 3 must be installed separately because yum will ignore/discard python2
RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    python3 \
    python3-devel \
    python3-pip \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    python \
    python-devel \
    python-distro \
    python-pip \
    python-requests \
    python-jsonschema \
    python-psutil \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

ARG python_version="python3"
ENV python=${python_version}

RUN ${python} -m pip install pyodbc distro jsonschema

RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
    wget -qO - https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    'irods-externals*' \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ARG clang_path="/opt/irods-externals/clang6.0-0/bin"
ENV PATH=${clang_path}:$PATH

ENV file_extension="rpm"
ENV package_manager="yum"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
