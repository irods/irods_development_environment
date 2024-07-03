# syntax=docker/dockerfile:1.5

FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    sed -i \
        -e 's/mirror.centos.org/vault.centos.org/g' \
        -e 's/^#.*baseurl=http/baseurl=http/g' \
        -e 's/^mirrorlist=http/#mirrorlist=http/g' \
        /etc/yum.repos.d/*.repo && \
    yum update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        centos-release-scl \
        epel-release \
        wget \
    && \
    sed -i \
        -e 's/mirror.centos.org/vault.centos.org/g' \
        -e 's/^#.*baseurl=http/baseurl=http/g' \
        -e 's/^mirrorlist=http/#mirrorlist=http/g' \
        /etc/yum.repos.d/*.repo && \
    rm -rf /tmp/*

# CERT LIFTeR - for newer flex and bison
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    rpm --import https://www.cert.org/forensics/repository/forensics-expires-2022-04-03.asc && \
    yum install -y https://forensics.cert.org/cert-forensics-tools-release-el7.rpm && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        ccache \
        openssl \
        openssl-devel \
        super \
        lsof \
        postgresql-server \
        unixODBC-devel \
        libjson-perl \
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
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    wget -qO - https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        'irods-externals*' \
    && \
    rm -rf /tmp/*

# NOTE: This step cannot be combined with the installation step(s) above. Certain packages will
# not be installed until certain other packages are installed. It's very sad and confusing.
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
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
        devtoolset-10-gcc \
        devtoolset-10-gcc-c++ \
        flex \
        bison \
    && \
    rm -rf /tmp/*

# For Python3 modules not available as packages:
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    yum install -y \
        cmake3 \
        spdlog-devel \
    && \
    python3 -m pip install \
        pyodbc \
    && \
    mkdir /tmp/cmake3-bin && \
    ln -s /usr/bin/cmake3 /tmp/cmake3-bin/cmake && \
    source /opt/rh/devtoolset-10/enable && \
    PATH=/tmp/cmake3-bin:$PATH python3 -m pip install \
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
    rm -rf /tmp/*

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ARG clang_path="/opt/irods-externals/clang6.0-0/bin"
ENV PATH=${clang_path}:$PATH

ENV file_extension="rpm"
ENV package_manager="yum"

ENV CCACHE_DIR="/irods_build_cache"
# Default to a reasonably large cache size
ENV CCACHE_MAXSIZE="64G"
# Allow for a lot of files (1.5M files, 300 per directory)
ENV CCACHE_NLEVELS="3"
# Allow any uid to use cache
ENV CCACHE_UMASK="000"

COPY --chmod=755 build_and_copy_packages_to_dir.sh /
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
