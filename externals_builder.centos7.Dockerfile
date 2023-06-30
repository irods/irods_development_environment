# syntax=docker/dockerfile:1.5

FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum update -y || [ "$?" -eq 100 ] && \
    rm -rf /tmp/*

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y \
        centos-release-scl \
        epel-release \
    && \
    yum install -y \
        sudo \
        git \
        python3 \
        python36-distro \
        devtoolset-10-gcc \
        devtoolset-10-gcc-c++ \
    && \
    rm -rf /tmp/*

ARG externals_repo="https://github.com/irods/externals"
ARG externals_branch="main"

WORKDIR /externals
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    git clone "${externals_repo}" -b "${externals_branch}" /externals && \
    ./install_prerequisites.py && \
    rm -rf /externals /tmp/*

# TODO: The following will enable the newer toolchain on interactive shell logins. The
# externals builder, however, is not an interactive shell, so this does not execute. This seems
# like a much better option than explicitly setting the PATH environment variable to check for
# new thing, as is being done below. Investigate making this effective for this builder.
#RUN echo "#!/bin/sh" > /etc/profile.d/devtoolset-10.sh && \
#    echo "" >> /etc/profile.d/devtoolset-10.sh && \
#    echo ". /opt/rh/devtoolset-10/enable" >> /etc/profile.d/devtoolset-10.sh

ENV PATH=/opt/rh/devtoolset-10/root/usr/bin:$PATH

ENV file_extension="rpm"
ENV package_manager="yum"

WORKDIR /
COPY --chmod=755 build_and_copy_externals_to_dir.sh /
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
