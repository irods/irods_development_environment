# syntax=docker/dockerfile:1.5

FROM rockylinux:9

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        dnf-plugins-core \
    && \
    dnf config-manager --set-enabled crb && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        sudo \
        cmake \
        git \
        python3 \
        python3-distro \
        python3-packaging \
    && \
    rm -rf /tmp/*

ARG externals_repo="https://github.com/irods/externals"
ARG externals_branch="main"

WORKDIR /externals
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    git clone "${externals_repo}" -b "${externals_branch}" /externals && \
    ./install_prerequisites.py && \
    rm -rf /externals /tmp/*

ENV file_extension="rpm"
ENV package_manager="dnf"

WORKDIR /
COPY --chmod=755 build_and_copy_externals_to_dir.sh /
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
