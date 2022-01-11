#! /bin/bash -e

set -x

usage() {
cat <<_EOF_
Builds iRODS repository, installs the dev/runtime packages, and then builds iCommands

Available options:

    --core-only             Only builds the core
    -d, --debug             Build with symbols for debugging
    -j, --jobs              Number of jobs for make tool
    -N, --ninja             Use ninja builder as the make tool
    --exclude-unit-tests    Indicates that iRODS unit tests should not be built
    --custom-externals      Path to custom externals packages received via volume mount
    -h, --help              This message
_EOF_
    exit
}

if [[ -z ${file_extension} ]] ; then
    echo "\$file_extension not defined"
    exit 1
fi

install_command=""
if [ "${file_extension}" == "rpm" ] ; then
    install_command="yum install -y"
elif [ "${file_extension}" == "deb" ] ; then
    install_command="apt install -fy --allow-downgrades"
fi

if [[ -z ${install_command} ]] ; then
    echo "platform unsupported"
    exit 1
fi

core_only=0
make_program="make"
make_program_config=""
build_jobs=0
debug_config=""
unit_test_config="-DIRODS_UNIT_TESTS_BUILD=YES"
custom_externals=""

while [ -n "$1" ] ; do
    case "$1" in
        --core-only)             core_only=1;;
        -N|--ninja)              make_program_config="-GNinja";
                                 make_program="ninja";;
        -j|--jobs)               shift; build_jobs=$(($1 + 0));;
        -d|--debug)              debug_config="-DCMAKE_BUILD_TYPE=Debug";;
        --exclude-unit-tests)    unit_test_config="-DIRODS_UNIT_TESTS_BUILD=NO";;
        --custom-externals)      shift; custom_externals=$1;;
        -h|--help)               usage;;
    esac
    shift
done

if [[ ! -z ${custom_externals} ]] ; then
    ${install_command} "${custom_externals}"/irods-externals-*."${file_extension}"
fi

build_jobs=$(( !build_jobs ? $(nproc) - 1 : build_jobs )) #prevent maxing out CPUs

echo "========================================="
echo "beginning build of iRODS server"
echo "========================================="

# Build iRODS
mkdir -p /irods_build && cd /irods_build
cmake ${make_program_config} ${debug_config} ${unit_test_config} /irods_source
if [[ -z ${build_jobs} ]] ; then
    ${make_program} package
else
    echo "using [${build_jobs}] threads"
    ${make_program} -j ${build_jobs} package
fi

# Copy packages to mounts
cp -r /irods_build/*."${file_extension}" /irods_packages/

# stop if --core-only option was used
if [[ ${core_only} -gt 0 ]] ; then
    exit
fi

echo "========================================="
echo "beginning build of iCommands"
echo "========================================="

# Install packages for building iCommands
${install_command} /irods_packages/irods-{runtime,dev}*."${file_extension}"

# Build iCommands
mkdir -p /icommands_build && cd /icommands_build
cmake ${make_program_config} ${debug_config} /icommands_source
if [[ -z ${build_jobs} ]] ; then
    ${make_program} package
else
    echo "using [${build_jobs}] threads"
    ${make_program} -j ${build_jobs} package
fi

# Copy packages to mounts
cp -r /icommands_build/*."${file_extension}" /irods_packages/
