FROM almalinux:8

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN dnf update -y || [ "$?" -eq 100 ] && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        epel-release \
        wget \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        python3-devel \
        python3-distro \
        python3-jsonschema \
        python3-packaging \
        python3-psutil \
        python3-pyodbc \
        python3-requests \
        openssl \
        openssl-devel \
        lsof \
        postgresql-server \
        unixODBC-devel \
        which \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

# For Python3 modules not available as packages:
RUN dnf install -y \
        python3-pip \
    && \
    python3 -m pip --no-cache-dir install \
        lief \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        dnf-plugin-config-manager \
    && \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    dnf config-manager -y --add-repo https://packages.irods.org/renci-irods.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    dnf config-manager -y --add-repo https://core-dev.irods.org/renci-irods-core-dev.yum.repo && \
    dnf config-manager -y --set-enabled renci-irods-core-dev && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        'irods-externals*' \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

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
        make \
        gcc-c++ \
        rpm-build \
        sudo \
        ninja-build \
        help2man \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

ENV file_extension="rpm"
ENV package_manager="dnf"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
