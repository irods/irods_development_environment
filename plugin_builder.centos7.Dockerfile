FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    epel-release \
    sudo \
    wget \
    git \
    python \
    python-pip \
    rpm-build \
    gcc-c++ \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN yum install -y python-pip && \
    pip install --upgrade 'pip<21.0' \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  git clone https://github.com/irods/irods_python_ci_utilities && \
  pip install -e /irods_python_ci_utilities

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
