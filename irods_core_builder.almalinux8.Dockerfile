FROM almalinux:8

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN dnf update -y || [ "$?" -eq 100 ] && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

RUN dnf install -y \
        epel-release \
        wget \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

RUN dnf install -y \
        python3 \
        python3-psutil \
        python3-requests \
        openssl \
        openssl-devel \
        lsof \
        postgresql-server \
        unixODBC-devel \
        which \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

# python3-devel must be installed because pyodbc requires building
RUN dnf install -y \
        gcc-c++ \
        make \
        python3-devel

# For Python3 modules not available as packages:
RUN python3 -m pip install pyodbc distro jsonschema

# TODO: when externals packages are published for almalinux:8, this section can be uncommented
#RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
#    wget -qO - https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo && \
#    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
#    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
#    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
#    yum clean all && \
#    rm -rf /var/cache/yum /tmp/*

#RUN yum install -y \
#        'irods-externals*' \
#    && \
#    yum clean all && \
#    rm -rf /var/cache/yum /tmp/*

# NOTE: This step cannot be combined with the installation step(s) above. Certain packages will
# not be installed until certain other packages are installed. It's very sad and confusing.
#
# For almalinux:8, the powertools repository should be enabled so that certain developer
# tools such as ninja-build and help2man can be installed.
RUN dnf install -y \
        dnf-plugins-core \
    && \
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf config-manager --set-enabled powertools \
    && \
    dnf install -y \
        git \
        pam-devel \
        fuse-devel \
        libcurl-devel \
        bzip2-devel \
        libxml2-devel \
        rpm-build \
        sudo \
        ninja-build \
        help2man \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ENV file_extension="rpm"
ENV package_manager="dnf"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
