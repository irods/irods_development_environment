#! /bin/bash

usage() {
cat <<_EOF_
Usage: ./build_image.sh [OPTIONS]...

Builds a new docker image.

Example:

    ./build_image.sh --image-name <arg> --irods-repo <arg> --irods-branch <arg> ...

Available options:

    --image-name            The name of the new docker image
    --cmake-path            Full path to the CMake binary (e.g. /opt/irods-externals/cmakeX.X.X/bin)
    --dockerfile            Dockerfile to build (default: ./Dockerfile)
    -h, --help              This message
_EOF_
    exit
}

# defaults
image_name=irods_ub16_builder
build_args=
dockerfile=Dockerfile.ub16

while [ -n "$1" ]; do
    case "$1" in
        --image-name)       shift; image_name=${1};;
        --cmake-path)       shift; build_args="$build_args --build-arg cmake_path=${1}";;
        --dockerfile)       shift; dockerfile=${1};;
        -h|--help)          usage;;
    esac
    shift
done

docker build -f $dockerfile -t $image_name $build_args .
