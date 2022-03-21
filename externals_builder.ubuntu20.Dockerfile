FROM ubuntu:20.04

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
        python3 \
        python3-distro \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ARG externals_branch="main"

WORKDIR /externals
RUN git clone https://github.com/irods/externals -b "${externals_branch}" /externals && \
    ./install_prerequisites.py && \
    rm -rf /externals

RUN update-alternatives --install /usr/local/bin/gcc gcc /usr/bin/gcc-10 1 && \
    update-alternatives --install /usr/local/bin/g++ g++ /usr/bin/g++-10 1 && \
    hash -r

ENV file_extension="deb"
ENV package_manager="apt"

WORKDIR /
COPY build_and_copy_externals_to_dir.sh /
RUN chmod u+x /build_and_copy_externals_to_dir.sh
ENTRYPOINT ["./build_and_copy_externals_to_dir.sh"]
