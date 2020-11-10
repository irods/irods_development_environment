#! /bin/bash -e

usage() {
cat <<_EOF_
Builds iRODS repository, installs the dev/runtime packages, and then builds iCommands

Available options:

    --server-only           Only builds the server
    -d, --debug             Build with symbols for debugging
    -j, --jobs              Number of jobs for make tool
    -N, --ninja)            Use ninja builder as the make tool
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

core_only=0
make_program="make"
make_program_config=""
build_jobs=0
debug_config=""
unit_test_config="-DIRODS_UNIT_TESTS_BUILD=YES"

while [ -n "$1" ]; do
    case "$1" in
        --core-only)             core_only=1;;
        -N|--ninja)              make_program_config="-GNinja";
                                 make_program="ninja";;
        -j|--jobs)               shift; build_jobs=$(($1 + 0));;
        -d|--debug)              debug_config="-DCMAKE_BUILD_TYPE=Debug";;
        --exclude-unit-tests)    unit_test_config="-DIRODS_UNIT_TESTS_BUILD=NO";;
        -h|--help)               usage;;
    esac
    shift
done

build_jobs=$(( !build_jobs ? $(nproc) - 1 : build_jobs )) #prevent maxing out CPUs

echo "========================================="
echo "beginning build of iRODS server"
echo "========================================="

# Build iRODS
mkdir -p /irods_build && cd /irods_build
cmake ${make_program_config} ${debug_config} ${unit_test_config} /irods_source
if [[ -z ${build_jobs} ]]; then
    ${make_program} package
else
    echo "using [${build_jobs}] threads"
    ${make_program} -j ${build_jobs} package
fi

# Copy packages to mounts
if [ "${DISTRIBUTION}" == "centos" ] ; then
    cp -r /irods_build/*.rpm /irods_packages/
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    cp -r /irods_build/*.deb /irods_packages/
fi

# stop if --server-only option was used
if [[ ${core_only} -gt 0 ]]; then
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
cmake ${make_program_config} ${debug_config} /icommands_source
if [[ -z ${build_jobs} ]]; then
    ${make_program} package
else
    echo "using [${build_jobs}] threads"
    ${make_program} -j ${build_jobs} package
fi

# Copy packages to mounts
if [ "${DISTRIBUTION}" == "centos" ] ; then
    cp -r /icommands_build/*.rpm /irods_packages/
elif [ "${DISTRIBUTION}" == "debian" ] ; then
    cp -r /icommands_build/*.deb /irods_packages/
fi
