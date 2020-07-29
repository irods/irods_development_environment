#! /bin/bash -e

usage() {
cat <<_EOF_
Builds iRODS repository, installs the dev/runtime packages, and then builds iCommands

Available options:

    --server-only           Only builds the server
    -j, --jobs              Number of jobs to use with make
    -h, --help              This message
_EOF_
    exit
}

# Detect distribution
if [ -e /etc/redhat-release ] ; then
    DISTRIBUTION="centos"
elif [ -e /etc/lsb-release ] ; then
    DISTRIBUTION="debian"
else
    DISTRIBUTION="unknown"
fi

server_only=0

while [ -n "$1" ]; do
    case "$1" in
        --server-only)           server_only=1;;
        -j|--jobs)               shift; build_jobs=${1};;
        -h|--help)               usage;;
    esac
    shift
done

echo "========================================="
echo "beginning build of iRODS server"
echo "========================================="

# Build iRODS
mkdir -p /irods_build && cd /irods_build
cmake /irods_source
if [[ -z ${build_jobs} ]]; then
    make -j package
else
    echo "using [${build_jobs}] threads"
    make -j ${build_jobs} package
fi

# Copy packages to mounts
if [ "${DISTRIBUTION}" == "centos" ] ; then
    cp -r /irods_build/*.rpm /irods_packages/
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    cp -r /irods_build/*.deb /irods_packages/
fi

# stop if --server-only option was used
if [[ ${server_only} -gt 0 ]]; then
    exit
fi

echo "========================================="
echo "beginning build of iCommands"
echo "========================================="

# Install packages for building iCommands.
if [ "${DISTRIBUTION}" == "centos" ] ; then
    rpm -i irods-{runtime,devel}*.rpm
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    dpkg -i irods-{runtime,dev}*.deb
fi

# Build icommands
mkdir -p /icommands_build && cd /icommands_build
cmake /icommands_source
if [[ -z ${build_jobs} ]]; then
    make -j package
else
    echo "using [${build_jobs}] threads"
    make -j ${build_jobs} package
fi

# Copy packages to mounts
if [ "${DISTRIBUTION}" == "centos" ] ; then
    cp -r /icommands_build/*.rpm /irods_packages/
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    cp -r /icommands_build/*.deb /irods_packages/
fi
