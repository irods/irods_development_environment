#! /bin/bash -e

# Detect distribution
if [ -e /etc/redhat-release ] ; then
    DISTRIBUTION="centos"
elif [ -e /etc/lsb-release ] ; then
    DISTRIBUTION="debian"
else
    DISTRIBUTION="unknown"
fi

# Build iRODS
mkdir -p /irods_build && cd /irods_build
cmake /irods_source
make -j package

# Install packages for building iCommands.
if [ "${DISTRIBUTION}" == "centos" ] ; then
    rpm -i irods-{runtime,devel}*.rpm
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    dpkg -i irods-{runtime,dev}*.deb
fi

# Build icommands
mkdir -p /icommands_build && cd /icommands_build
cmake /icommands_source
make -j package

# Copy packages to mounts
if [ "${DISTRIBUTION}" == "centos" ] ; then
    cp -r /irods_build/*.rpm /irods_packages/
    cp -r /icommands_build/*.rpm /irods_packages/
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    cp -r /irods_build/*.deb /irods_packages/
    cp -r /icommands_build/*.deb /irods_packages/
fi
