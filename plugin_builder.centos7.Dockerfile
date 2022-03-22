FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    epel-release \
    gcc-c++ \
    git \
    rpm-build \
    sudo \
    wget \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*


# python 2 and 3 must be installed separately because yum will ignore/discard python2
RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    python3 \
    python3-pip \
    python3-devel \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    python \
    python-pip \
    python-devel \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

ARG python_version="python3"
ENV python=${python_version}

ARG python_ci_utilities_url="https://github.com/irods/irods_python_ci_utilities"
ENV ci_url=${python_ci_utilities_url}

ARG python_ci_utilities_branch="main"
ENV ci_branch=${python_ci_utilities_branch}

RUN \
  git clone ${ci_url} -b ${ci_branch} && \
  ${python} -m pip install /irods_python_ci_utilities && \
  rm -r /irods_python_ci_utilities

ENV file_extension="rpm"
ENV package_manager="yum"

COPY build_and_copy_plugin_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_plugin_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_plugin_packages_to_dir.sh"]
