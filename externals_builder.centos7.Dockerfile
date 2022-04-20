FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

# Make sure we're starting with an up-to-date image
RUN yum update -y || [ "$?" -eq 100 ] && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN yum install -y \
        centos-release-scl \
        epel-release \
    && \
    yum install -y \
        sudo \
        git \
        python3 \
        python3-distro \
        devtoolset-10-gcc \
        devtoolset-10-gcc-c++ \
    && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

ARG externals_branch="main"

WORKDIR /externals
RUN git clone https://github.com/irods/externals -b "${externals_branch}" /externals && \
    python3 -m venv build_env && \
    source build_env/bin/activate && \
    ./install_prerequisites.py && \
    rm -rf /externals && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

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
COPY build_and_copy_externals_to_dir.sh /
RUN chmod u+x /build_and_copy_externals_to_dir.sh
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
