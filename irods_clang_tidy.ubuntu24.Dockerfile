# syntax=docker/dockerfile:1.5

FROM ubuntu:24.04

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
        bison \
        catch2 \
        cmake \
        curl \
        flex \
        g++ \
        gnupg \
        libarchive-dev \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libfmt-dev \
        libpam0g-dev \
        libspdlog-dev \
        libssl-dev \
        libsystemd-dev \
        libxml2-dev \
        lsb-release \
        make \
        nlohmann-json3-dev \
        odbc-postgresql \
        python3-dev \
        python3-distro \
        python3-psutil \
        unixodbc \
        unixodbc-dev \
        wget \
        zlib1g-dev \
    && \
    rm -rf /tmp/*

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | \
        gpg \
            --no-options \
            --no-default-keyring \
            --no-auto-check-trustdb \
            --homedir /dev/null \
            --no-keyring \
            --import-options import-export \
            --output /etc/apt/keyrings/renci-irods-archive-keyring.pgp \
            --import \
        && \
    echo "deb [signed-by=/etc/apt/keyrings/renci-irods-archive-keyring.pgp arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | \
        tee /etc/apt/sources.list.d/renci-irods.list && \
    wget -qO - https://core-dev.irods.org/irods-core-dev-signing-key.asc | \
        gpg \
            --no-options \
            --no-default-keyring \
            --no-auto-check-trustdb \
            --homedir /dev/null \
            --no-keyring \
            --import-options import-export \
            --output /etc/apt/keyrings/renci-irods-core-dev-archive-keyring.pgp \
            --import \
        && \
    echo "deb [signed-by=/etc/apt/keyrings/renci-irods-core-dev-archive-keyring.pgp arch=amd64] https://core-dev.irods.org/apt/ $(lsb_release -sc) main" | \
        tee /etc/apt/sources.list.d/renci-irods-core-dev.list

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        irods-externals-boost1.81.0-2 \
        irods-externals-clang16.0.6-0 \
        irods-externals-jsoncons0.178.0-0 \
        irods-externals-nanodbc2.13.0-3 \
    && \
    rm -rf /tmp/*

COPY --chmod=755 run_clangtidy_on_codebase.sh /
ENTRYPOINT ["/run_clangtidy_on_codebase.sh"]
