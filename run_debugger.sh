#!/bin/bash -e

volumes_file=""
dry_run=""
do_source_build="."
builder_build="y"
runner_build="y"
runner_run="y"
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
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/irods"

usage()
{
    [ $# -gt 0 ] && echo "$*";
    echo "Usage: bash '$0' --volume-ro /outside /inside --volume-rw /outside_rw /inside_rw --dry-run"
    echo "       abbreviated forms : -r => --volume-ro"
    echo "                         : -w => --volume-rw"
    echo "                         : -d => --devroot"
    echo "                         : -p => --platform-os (set to '$OS_NAME')"
    echo "                         : -V => --volumes-file"
    echo "                         : -b => --skip-builder-build"
    echo "                         : -s => --skip-source-build"
    echo "                         : -e => --skip-runner-build"
    echo "                         : -u => --skip-runner-run"
    echo "                         : -g => --debug-source-build"
    echo "                         : -j => --jobs"
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
        -b|--skip-builder-build) builder_build="";;
        -s|--skip-source-build) do_source_build="";;
        -e|--skip-runner-build) runner_build="";;
        -u|--skip-runner-run) runner_run="";;
        -n|--no-cache) NO_CACHE="--no-cache";;
        -g|--debug*) do_source_build=".--debug";;
        -N|--ninja) BUILD_OPTIONS+=" --ninja";;
        -j|--jobs) BUILD_OPTIONS+=" --jobs $2"; shift;;
        *) usage bad option "'$1'" ;;
    esac
    shift
done

declare -A Os_Map=( ['ubuntu16']='ubuntu:16.04'
                    ['ubuntu18']='ubuntu:18.04'
                    ['ubuntu20']='ubuntu:20.04'
                    ['debian11']='debian:11'
                    ['almalinux8']='almalinux:8'
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

DEBUGGER_IMAGE="irods_debuggers.${OS_NAME}"
BUILDER_IMAGE="irods_core_builder.${OS_NAME}"
RUNNER_IMAGE="irods_runner.${OS_NAME}"

DEBUGGER_DOCKERFILE="build_debuggers.${OS_NAME}.Dockerfile"
BUILDER_DOCKERFILE="irods_core_builder.${OS_NAME}.Dockerfile"
RUNNER_DOCKERFILE="irods_runner.${OS_NAME}.Dockerfile"

# get/init runner number
RUNNER_INT_FILE="${CACHE_DIR}/new_runner_number.${OS_NAME}"
RUNNER_INT="0"
RUNNER_NUMBER="0000"
mkdir -p "${CACHE_DIR}"
if [ -f "${RUNNER_INT_FILE}" ]; then
    RUNNER_INT="$(<"${RUNNER_INT_FILE}")"
    RUNNER_NUMBER=$(printf "%04d" "${RUNNER_INT}")
fi
RUNNER_NAME="irods_runner.${RUNNER_NUMBER}.${OS_NAME}"
while [ "$(docker ps -aq -f name=${RUNNER_NAME})" ]; do
    RUNNER_INT=$((RUNNER_INT+1))
    RUNNER_NUMBER=$(printf "%04d" "${RUNNER_INT}")
    RUNNER_NAME="irods_runner.${RUNNER_NUMBER}.${OS_NAME}"
done

if [ -n "$dry_run" ]; then  # -- print mount options for the debugger run
    echo "--- using OS_NAME='$OS_NAME' base_image='$base_image' ---"
    if [ -e "${DEBUGGER_DOCKERFILE}" ]; then
        echo "    DEBUGGER_IMAGE:   '${DEBUGGER_IMAGE}'"
    fi
    echo "    BUILDER_IMAGE:    '${BUILDER_IMAGE}'"
    if [ -e "${RUNNER_DOCKERFILE}" ]; then
        echo "    RUNNER_IMAGE:     '${RUNNER_IMAGE}'"
        echo "    RUNNER_CONTAINER: '${RUNNER_NAME}'"
    fi
    echo -e "\ndocker run \n"
    n=0; echo $'\t'$n
    for x in "${vol_mounts[@]}"; do
        echo $'\t'$((++n))$'\t'$x
    done
    if [ -e "${RUNNER_DOCKERFILE}" ]; then
        echo -e "\nDOCKER_OPTIONS:${DOCKER_OPTIONS}" \
                "\nDEBUG_OPTIONS:${DEBUG_OPTIONS}"
    fi
    exit 1
else
    build_dir=$(dirname "$0")
    cd "$build_dir" || { echo >&2 "cannot cd to docker build environment"; exit 2; }
    if [ -e "${DEBUGGER_DOCKERFILE}" ]; then
        docker build --build-arg debugger_base=${base_image}  -f "${DEBUGGER_DOCKERFILE}" -t "${DEBUGGER_IMAGE}" . ${NO_CACHE}
        RUNNER_BASE="${DEBUGGER_IMAGE}"
    else
        RUNNER_BASE="${base_image}"
    fi
    if [ -n "$builder_build" ] || [ -n "$do_source_build" ]; then
        docker build -t "${BUILDER_IMAGE}" -f "${BUILDER_DOCKERFILE}" . ${NO_CACHE}
    fi
    if [ -n "$do_source_build" ]; then
        docker run --rm "${vol_mounts[@]}" -it -e "TERM=$TERM" "${BUILDER_IMAGE}" ${do_source_build:1} ${BUILD_OPTIONS}
    fi
    if [ -e "${RUNNER_DOCKERFILE}" ]; then
        if [ -n "$runner_build" ]; then
            docker build --build-arg runner_base="${RUNNER_BASE}" -t "${RUNNER_IMAGE}" -f "${RUNNER_DOCKERFILE}" . ${NO_CACHE}
        fi
        if [ -n "$runner_run" ]; then
            echo -n "$((RUNNER_INT+1))" > "${RUNNER_INT_FILE}"
            docker run "${vol_mounts[@]}" ${DOCKER_OPTIONS} ${DEBUG_OPTIONS} --name "${RUNNER_NAME}" "${RUNNER_IMAGE}"
        fi
    fi
fi
