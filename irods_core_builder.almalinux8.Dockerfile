FROM almalinux:8

SHELL [ "/usr/bin/bash", "-c" ]

RUN \
  dnf update -y && \
  dnf install -y \
    epel-release \
    wget \
  && \
  dnf clean all && \
  rm -rf /var/cache/dnf /tmp/*

RUN \
  dnf update -y && \
  dnf install -y \
    dnf-plugins-core \
  && \
  dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
  dnf config-manager --set-enabled powertools && \
  dnf update -y && \
  dnf install -y \
    bzip2-devel \
    fuse-devel \
    gcc-c++ \
    make \
    git \
    help2man \
    libcurl-devel \
    libxml2-devel \
    lsof \
    ninja-build \
    openssl \
    openssl-devel \
    pam-devel \
    postgresql-server \
    python3 \
    python3-devel \
    python3-psutil \
    python3-requests \
    rpm-build \
    sudo \
    unixODBC-devel \
    which \
  && \
  dnf clean all && \
  rm -rf /var/cache/dnf /tmp/*

ARG python_version="python3"
ENV python=${python_version}

RUN ${python} -m pip install pyodbc distro jsonschema

# TODO: when externals packages are published for almalinux:8, this section can be uncommented
#RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
    #wget -qO - https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo && \
    #rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    #wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    #yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    #yum clean all && \
    #rm -rf /var/cache/yum /tmp/*

#RUN \
  #yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  #yum install -y \
    #'irods-externals*' \
  #&& \
  #yum clean all && \
  #rm -rf /var/cache/yum /tmp/*

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ENV file_extension="rpm"
ENV package_manager="dnf"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
