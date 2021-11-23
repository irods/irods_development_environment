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
python /irods_plugin_source/irods_consortium_continuous_integration_build_hook.py \
    --irods_packages_root_directory /irods_packages $@

# Copy packages to mounts
if [ "${DISTRIBUTION}" == "centos" ] ; then
    cp -r /irods_plugin_build/*.rpm /irods_plugin_packages/
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    cp -r /irods_plugin_build/*.deb /irods_plugin_packages/
fi
