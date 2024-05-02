# syntax=docker/dockerfile:1.5

FROM almalinux:8

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
    dnf config-manager --set-enabled powertools && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked \
    --mount=type=cache,target=/var/cache/yum,sharing=locked \
    dnf install -y \
        sudo \
        git \
        python3 \
        python3-distro \
        python3-packaging \
        gcc-toolset-11 \
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

# TODO: The following will enable the newer toolchain on interactive shell logins. The
# externals builder, however, is not an interactive shell, so this does not execute. This seems
# like a much better option than explicitly setting the PATH environment variable to check for
# new thing, as is being done below. Investigate making this effective for this builder.
#RUN echo "#!/bin/sh" > /etc/profile.d/gcc-toolset-11.sh && \
#    echo "" >> /etc/profile.d/gcc-toolset-11.sh && \
#    echo ". /opt/rh/gcc-toolset-11/enable" >> /etc/profile.d/gcc-toolset-11.sh

ENV PATH=/opt/rh/gcc-toolset-11/root/usr/bin:$PATH
ENV IRODS_EXTERNALS_GCC_PREFIX=/opt/rh/gcc-toolset-11/root/usr

ENV file_extension="rpm"
ENV package_manager="dnf"

WORKDIR /
COPY --chmod=755 build_and_copy_externals_to_dir.sh /
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
