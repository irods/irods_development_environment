#! /bin/bash -e

set -x

usage() {
cat <<_EOF_
Builds iRODS repository, installs the dev/runtime packages, and then builds iCommands

Available options:

    --core-only             Only builds the iRODS packages
    --icommands-only        Only builds the iCommands packages
    --irods-repo-url        Git URL to remote iRODS repository to clone and build
    --irods-commitish       Commit-ish (sha, branch, tag, etc.) to checkout in iRODS
    --icommands-repo-url    Git URL to remote iCommands repository to clone and build
    --icommands-commitish   Commit-ish (sha, branch, tag, etc.) to checkout in iCommands
    -C, --ccache            Enables ccache for rapid subsequent builds
    -d, --debug             Build with symbols for debugging
    -j, --jobs              Number of jobs for make tool
    -N, --ninja             Use ninja builder as the make tool
    --exclude-unit-tests    Indicates that iRODS unit tests should not be built
    --exclude-microservice-tests
                            Indicates that iRODS tests implemented as microservices
                            should not be built
    --enable-address-sanitizer
                            Indicates that Address Sanitizer should be enabled
    --enable-undefined-behavior-sanitizer
                            Indicates that Undefined Behavior Sanitizer should be enabled
    --enable-undefined-behavior-sanitizer-implicit-conversion
                            Indicates that the implicit conversion check of Undefined
                            Behavior Sanitizer should be enabled
    --custom-externals      Path to custom externals packages received via volume mount
    -h, --help              This message
_EOF_
    exit
}

if [[ -z ${package_manager} ]] ; then
    echo "\$package_manager not defined"
    exit 1
fi

if [[ -z ${file_extension} ]] ; then
    echo "\$file_extension not defined"
    exit 1
fi

supported_package_manager_frontends=(
    "apt-get"
    "yum"
    "dnf"
)

if [[ ! " ${supported_package_manager_frontends[*]} " =~ " ${package_manager} " ]]; then
    echo "unsupported platform or package manager"
    exit 1
fi

install_packages() {
    if [ "${package_manager}" == "apt-get" ] ; then
        pkg_files=()
        for pkg_file in "$@"; do
            pkg_files+=("$(realpath "${pkg_file}")")
        done
        apt-get update
        apt-get install -y --allow-downgrades "${pkg_files[@]}"
    elif [ "${package_manager}" == "yum" ] ; then
        yum install -y "$@"
    elif [ "${package_manager}" == "dnf" ] ; then
        dnf install -y "$@"
    fi
}

core_only=0
icommands_only=0
irods_repo_url="https://github.com/irods/irods"
irods_commitish="main"
icommands_repo_url="https://github.com/irods/irods_client_icommands"
icommands_commitish="main"
make_program="make"
make_program_config=""
build_jobs=0
debug_config="-DCMAKE_BUILD_TYPE=Release"
unit_test_config="-DIRODS_UNIT_TESTS_BUILD=YES"
msi_test_config="-DIRODS_MICROSERVICE_TEST_PLUGINS_BUILD=YES"
enable_asan="-DIRODS_ENABLE_ADDRESS_SANITIZER=NO"
custom_externals=""

common_cmake_args=(
    -DCMAKE_COLOR_MAKEFILE=ON
    -DCMAKE_VERBOSE_MAKEFILE=ON
)

while [ -n "$1" ] ; do
    case "$1" in
        --core-only)                  core_only=1;;
        --icommands-only)             icommands_only=1;;
        --irods-repo-url)             shift; irods_repo_url="$1";;
        --irods-commitish)            shift; irods_commitish="$1";;
        --icommands-repo-url)         shift; icommands_repo_url="$1";;
        --icommands-commitish)        shift; icommands_commitish="$1";;
        -N|--ninja)                   make_program_config="-GNinja";
                                      make_program="ninja";;
        -j|--jobs)                    shift; build_jobs=$(($1 + 0));;
        -d|--debug)                   debug_config="-DCMAKE_BUILD_TYPE=Debug -DCPACK_DEBIAN_COMPRESSION_TYPE=none";;
        -C|--ccache)                  common_cmake_args+=(-DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache);;
        --exclude-unit-tests)         unit_test_config="-DIRODS_UNIT_TESTS_BUILD=NO";;
        --exclude-microservice-tests) msi_test_config="-DIRODS_MICROSERVICE_TEST_PLUGINS_BUILD=NO";;
        --enable-address-sanitizer)   enable_asan="-DIRODS_ENABLE_ADDRESS_SANITIZER=YES";;
        --enable-undefined-behavior-sanitizer)   enable_ubsan="-DIRODS_ENABLE_UNDEFINED_BEHAVIOR_SANITIZER=YES";;
        --enable-undefined-behavior-sanitizer-implicit-conversion)    enable_ubsan_implicit_conversion="-DIRODS_ENABLE_UNDEFINED_BEHAVIOR_SANITIZER_IMPLICIT_CONVERSION_CHECK=YES";;
        --custom-externals)           shift; custom_externals=$1;;
        -h|--help)                    usage;;
    esac
    shift
done

if [[ ! -z ${custom_externals} ]] ; then
    install_packages "${custom_externals}"/irods-externals-*."${file_extension}"
fi

build_jobs=$(( !build_jobs ? $(nproc) - 1 : build_jobs )) #prevent maxing out CPUs

# skip building iRODS packages if --icommands-only was used
if [[ ${icommands_only} -eq 0 ]] ; then
    if [[ ! -d /irods_source ]] ; then
        # If the source directory does not exist, we clone one from a remote source.
        git clone "${irods_repo_url}" /irods_source --recurse-submodules
        cd /irods_source && git checkout "${irods_commitish}" && cd -
    fi

    echo "========================================="
    echo "beginning build of iRODS server"
    echo "========================================="

    # Build iRODS
    mkdir -p /irods_build && cd /irods_build
    cmake ${make_program_config} ${debug_config} "${common_cmake_args[@]}" ${unit_test_config} ${msi_test_config} ${enable_asan} ${enable_ubsan} ${enable_ubsan_implicit_conversion} /irods_source
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
fi

# Install packages for building other components
if [ "${file_extension}" == "rpm" ] ; then
    install_packages /irods_build/irods-{runtime,devel}*."${file_extension}"
else
    install_packages /irods_build/irods-{runtime,dev}*."${file_extension}"
fi

echo "========================================="
echo "beginning build of iCommands"
echo "========================================="

if [[ ! -d /icommands_source ]] ; then
    # If the source directory does not exist, we clone one from a remote source.
    git clone "${icommands_repo_url}" /icommands_source --recurse-submodules
    cd /irods_source && git checkout "${icommands_commitish}" && cd -
fi

# Build iCommands
mkdir -p /icommands_build && cd /icommands_build
cmake ${make_program_config} ${debug_config} "${common_cmake_args[@]}" ${enable_asan} ${enable_ubsan} ${enable_ubsan_implicit_conversion} /icommands_source
if [[ -z ${build_jobs} ]] ; then
    ${make_program} package
else
    echo "using [${build_jobs}] threads"
    ${make_program} -j ${build_jobs} package
fi

# Copy packages to mounts
cp -r /icommands_build/*."${file_extension}" /irods_packages/
