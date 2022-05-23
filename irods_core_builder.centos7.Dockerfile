FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN yum update -y || [ "$?" -eq 100 ] && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN yum install -y \
        epel-release \
        wget \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

# python 2 and 3 must be installed separately because yum will ignore/discard python2
RUN yum install -y \
        openssl \
        openssl-devel \
        super \
        lsof \
        postgresql-server \
        unixODBC-devel \
        libjson-perl \
    && \
    yum install -y \
        python \
        python-devel \
        python-distro \
        python2-packaging \
        python2-pip \
        python2-jsonschema \
        python2-psutil \
        python-requests \
        pyodbc \
    && \
    yum install -y \
        python36 \
        python3-devel \
        python3-distro \
        python3-packaging \
        python3-pip \
        python36-jsonschema \
        python36-psutil \
        python36-requests \
    && \
    pip --no-cache-dir install --upgrade 'pip<21.0' && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
    wget -qO - https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN yum install -y \
        'irods-externals*' \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

# NOTE: This step cannot be combined with the installation step(s) above. Certain packages will
# not be installed until certain other packages are installed. It's very sad and confusing.
RUN yum install -y \
        git \
        ninja-build \
        pam-devel \
        krb5-devel \
        fuse-devel \
        which \
        libcurl-devel \
        bzip2-devel \
        libxml2-devel \
        zlib-devel \
        make \
        gcc \
        gcc-c++ \
        help2man \
        rpm-build \
        sudo \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

# For Python3 modules not available as packages:
RUN yum install -y \
        cmake3 \
        spdlog-devel \
        centos-release-scl \
    && \
    yum install -y \
        devtoolset-11 \
    && \
    python3 -m pip --no-cache-dir install \
        pyodbc \
    && \
    mkdir /tmp/cmake3-bin && \
    ln -s /usr/bin/cmake3 /tmp/cmake3-bin/cmake && \
    source /opt/rh/devtoolset-11/enable && \
    PATH=/tmp/cmake3-bin:$PATH python3 -m pip --no-cache-dir install \
        lief \
            --global-option="--lief-no-cache" \
            --global-option="--ninja" \
            --global-option="--lief-no-pe" \
            --global-option="--lief-no-macho" \
            --global-option="--lief-no-android" \
            --global-option="--lief-no-art" \
            --global-option="--lief-no-vdex" \
            --global-option="--lief-no-oat" \
            --global-option="--lief-no-dex" \
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
