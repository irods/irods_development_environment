# syntax=docker/dockerfile:1.5

FROM debian:12

SHELL [ "/bin/bash", "-c" ]
ENV DEBIAN_FRONTEND=noninteractive

# Re-enable apt caching for RUN --mount
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    rm -rf /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        apt-transport-https \
        catch2 \
        ccache \
        cmake \
        g++-12 \
        gcc \
        gcc-12 \
        git \
        gnupg \
        help2man \
        libarchive-dev \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libfmt-dev \
        libfuse-dev \
        libjson-perl \
        libkrb5-dev \
        libpam0g-dev \
        libspdlog-dev \
        libssl-dev \
        libsystemd-dev \
        libxml2-dev \
        lsb-release \
        lsof \
        make \
        ninja-build \
        nlohmann-json3-dev \
        odbc-postgresql \
        postgresql \
        python3 \
        python3-dev \
        python3-distro \
        python3-jsonschema \
        python3-packaging \
        python3-psutil \
        python3-pyodbc \
        python3-requests \
        sudo \
        super \
        unixodbc-dev \
        wget \
        zlib1g-dev \
        flex \
        bison \
    && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    --mount=type=cache,target=/root/.cache/wheel,sharing=locked \
    apt-get update && \
    apt-get install -y \
        python3-pip \
    && \
    pip3 install --break-system-packages lief && \
    rm -rf /tmp/*

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list && \
    wget -qO - https://core-dev.irods.org/irods-core-dev-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://core-dev.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods-core-dev.list

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        'irods-externals*' \
    && \
    rm -rf /tmp/*

RUN update-alternatives --install /usr/local/bin/gcc gcc /usr/bin/gcc-12 1 && \
    update-alternatives --install /usr/local/bin/g++ g++ /usr/bin/g++-12 1 && \
    hash -r

ENV file_extension "deb"
ENV package_manager "apt-get"

ENV CCACHE_DIR="/irods_build_cache"
# Default to a reasonably large cache size
ENV CCACHE_MAXSIZE="64G"
# Allow for a lot of files (1.5M files, 300 per directory)
ENV CCACHE_NLEVELS="3"
# Allow any uid to use cache
ENV CCACHE_UMASK="000"

COPY --chmod=755 build_and_copy_packages_to_dir.sh /
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]
