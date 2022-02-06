#
# iRODS Runner
#
ARG runner_base=centos:7
FROM ${runner_base} as irods-runner

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    epel-release \
    sudo \
    wget \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    rsyslog \
    python \
    python2-psutil \
    python-requests \
    python2-jsonschema \
    python36 \
    python36-psutil \
    python36-requests \
    openssl \
    openssl-devel \
    super \
    lsof \
    postgresql-server \
    unixODBC-devel \
    pyodbc \
    libjson-perl \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

# For Python3 modules not available as packages in Centos 7:
RUN yum install -y \
        gcc-c++ \
        make \
        python3-devel # pyodbc requires building
RUN python3 -m pip install pyodbc \
      distro \
      jsonschema

RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
    wget -qO - https://packages.irods.org/renci-irods.yum.repo | sudo tee /etc/yum.repos.d/renci-irods.yum.repo && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | sudo tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    'irods-externals*' \
    irods-runtime-4.2.0-1.x86_64 \
    irods-icommands-4.2.0-1.x86_64 \
    irods-server-4.2.0-1.x86_64 \
    irods-database-plugin-postgres-4.2.0-1.x86_64 \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

ADD ICAT.sql /
ADD keep_alive.sh /keep_alive.sh
RUN chmod +x /keep_alive.sh
ENTRYPOINT ["/keep_alive.sh"]
