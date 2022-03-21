FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

# Make sure we're starting with an up-to-date image
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

RUN apt update && \
    apt install -y \
        sudo \
        git \
        python \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ARG externals_branch="4-2-stable"

WORKDIR /externals
RUN git clone https://github.com/irods/externals -b "${externals_branch}" /externals && \
    ./install_prerequisites.py && \
    rm -rf /externals

ENV file_extension="deb"
ENV package_manager="apt-get"

WORKDIR /
COPY build_and_copy_externals_to_dir.sh /
RUN chmod u+x /build_and_copy_externals_to_dir.sh
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
