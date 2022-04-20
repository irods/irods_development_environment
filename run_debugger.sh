#!/bin/bash -e

volumes_file=""
dry_run=""
do_source_build="."
OS_NAME="ubuntu18"
DEVROOT=""
NO_CACHE=""
BUILD_OPTIONS=""
DOCKER_OPTIONS="
                 -d -i -t "
DEBUG_OPTIONS="
                 --cap-add=SYS_PTRACE
                 --security-opt seccomp=unconfined
                 --privileged "
usage()
{
    [ $# -gt 0 ] && echo "$*";
    echo "Usage: bash '$0' --volume-ro /outside /inside --volume-rw /outside_rw /inside_rw --dry-run"
    echo "       abbreviated forms : -r => --volume-ro"
    echo "                         : -w => --volume-rw"
    echo "                         : -d => --devroot"
    echo "                         : -p => --platform-os (set to '$OS_NAME')"
    echo "                         : -V => --volumes-file"
    echo "                         : -s => --skip-source-build"
    echo "                         : -g => --debug-source-build"
    exit 127
} >&2

declare -A volumes_ro=() volumes_rw=()
vol_mounts=()

while [[ $1 = -* ]]; do
    case $1 in
        -h|--help) usage ;;
        --dry*) dry_run=1;;
        -p|--platform-os) shift; OS_NAME="$1";;
        -V|--volumes-file) shift; volumes_file="$1";;
        -r|--volume-ro) shift; vol_mounts+=( "-v"  "$1":"$2":ro ); shift ;;
        -w|--volume-rw) shift; vol_mounts+=( "-v"  "$1":"$2" )   ; shift ;;
        -d|--devroot) shift; DEVROOT="$1";;
        -s|--skip-source-build) do_source_build="";;
        -n|--no-cache) NO_CACHE="--no-cache";;
        -g|--debug*) do_source_build=".--debug";;
        -N|--ninja) BUILD_OPTIONS+=" --ninja";;
        *) usage bad option "'$1'" ;;
    esac
    shift
done

declare -A Os_Map=( ['ubuntu16']='ubuntu:16.04'
                    ['ubuntu18']='ubuntu:18.04'
                    ['centos7']='centos:7' )

base_image=${Os_Map["$OS_NAME"]}

if [ -n "$volumes_file" ]
then
    source "$volumes_file"
    [ -n "$exit_code" ] && exit $((0+exit_code))
else
    # -----------------------------------------------------
    #  For a custom setup of host-guest volume directories:

    #  copy this section into a volumes_file.XYZ and add own custom paths.
    #  Example file: ./volumes.include.sh

    volumes_ro=( # add read-only container mounts, eg:
                 # ['/path_to_source'] = '/full/host/path/to/source'
                 # ...
    )
    volumes_rw=( # add read-write container mounts, eg:
                 # ['/container/path/to/packages'] = '/host/path/to/packages_output'
    )
    # ---------------------------------------------------
fi

# --  assemble -v options for Docker commands

if [ "${#vol_mounts[@]}" -eq 0 ]; then
    for d in "${!volumes_rw[@]}"; do           # read-write mounts
        rlpath=$(realpath "${volumes_rw[$d]}")
        vol_mounts+=("-v" "$rlpath:$d")
    done
    for d in "${!volumes_ro[@]}"; do           # read-only mounts
        rlpath=$(realpath "${volumes_ro[$d]}")
        vol_mounts+=("-v" "$rlpath:$d:ro")
    done
fi

IMAGE=irods_runner."$OS_NAME"

if [ -n "$dry_run" ]; then  # -- print mount options for the debugger run
    echo "--- using OS_NAME='$OS_NAME' base_image='$base_image' ---"
    echo "    IMAGE: '${IMAGE}'"
    echo -e "\ndocker run \n"
    n=0; echo $'\t'$n
    for x in "${vol_mounts[@]}"; do
        echo $'\t'$((++n))$'\t'$x
    done
    echo -e "\nDOCKER_OPTIONS:${DOCKER_OPTIONS}" \
            "\nDEBUG_OPTIONS:${DEBUG_OPTIONS}"
    exit 1
else
    build_dir=$(dirname "$0")
    cd "$build_dir" || { echo >&2 "cannot cd to docker build environment"; exit 2; }
    docker build --build-arg debugger_base=${base_image}  -f build_debuggers."$OS_NAME".Dockerfile -t debuggers."$OS_NAME" . ${NO_CACHE}
    if [ -n "$do_source_build" ]; then
        docker build -t irods_core_builder."$OS_NAME" -f irods_core_builder."$OS_NAME".Dockerfile . ${NO_CACHE}
        docker run "${vol_mounts[@]}" irods_core_builder."$OS_NAME" ${do_source_build:1} ${BUILD_OPTIONS}
    fi
    docker build --build-arg runner_base=debuggers."$OS_NAME" -t "${IMAGE}" -f irods_runner."$OS_NAME".Dockerfile . ${NO_CACHE}
    docker run "${vol_mounts[@]}" ${DOCKER_OPTIONS} ${DEBUG_OPTIONS} "${IMAGE}"
fi
