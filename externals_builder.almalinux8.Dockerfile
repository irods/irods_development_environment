FROM almalinux:8

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN dnf update -y || [ "$?" -eq 100 ] && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

RUN dnf install -y \
        sudo \
        git \
        python3 \
        python3-pip \
        python3-distro \
        gcc-toolset-11 \
    && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

ARG externals_branch="main"

WORKDIR /externals
RUN git clone https://github.com/irods/externals -b "${externals_branch}" /externals && \
    python3 -m venv build_env && \
    source build_env/bin/activate && \
    python3 -m pip --no-cache-dir install distro && \
    ./install_prerequisites.py && \
    rm -rf /externals && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/*

# TODO: The following will enable the newer toolchain on interactive shell logins. The
# externals builder, however, is not an interactive shell, so this does not execute. This seems
# like a much better option than explicitly setting the PATH environment variable to check for
# new thing, as is being done below. Investigate making this effective for this builder.
#RUN echo "#!/bin/sh" > /etc/profile.d/gcc-toolset-11.sh && \
#    echo "" >> /etc/profile.d/gcc-toolset-11.sh && \
#    echo ". /opt/rh/gcc-toolset-11/enable" >> /etc/profile.d/gcc-toolset-11.sh

ENV PATH=/opt/rh/gcc-toolset-11/root/usr/bin:$PATH

ENV file_extension="rpm"
ENV package_manager="dnf"

WORKDIR /
COPY build_and_copy_externals_to_dir.sh /
RUN chmod u+x /build_and_copy_externals_to_dir.sh
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
