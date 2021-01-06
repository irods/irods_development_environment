#!/bin/bash

if [ ${CHK-1} ] ; then
[ $(id -u) = 0 ] || { echo "Please run this script as root." >&2; exit 1; }
fi

# -- BEGIN CONFIGURATION OPTIONS --

CMAKE_PREFIX="/opt/irods-externals/cmake"
CLANG_PREFIX="/opt/irods-externals/clang"
CLANG_RUNTIME_PREFIX="/opt/irods-externals/clang-runtime"

declare -A LLVM_TO_KOUTHEIR_VERSION_LOOKUP=(
    ["6.0.0"]="5ffbf2487bf8da7f08bc1c8650a4396d2ff15403"
)

# -- END CONFIGURATION OPTIONS --

#
# package_max_version determine the maximum of several versions of a package in iRODS externals
#
package_max_version() (  # deliberate subshell
    [ -z "$1" ] && exit
    PACKAGE_PREFIX=$1
    shopt -s nullglob
    if [ -n "$2" ]; then
      version_string_pattern="$2"
    else
      version_string_pattern="[0-9][-.0-9]*"
    fi
    max=""
    paths=( ${PACKAGE_PREFIX}${version_string_pattern} )
    [ ${#paths[*]} -gt 0 ] && \
    for y in ${paths[*]}; do
        max=$(get_max "${y#${PACKAGE_PREFIX}}" "$max")
    done
    echo $max
)

get_max() { # -- get max of two (X,Y,Z) tuples --
    local z y=0 gt=""
    local IFS=".-"  # for splitting version numbers of the form "X[-.]Y..." into (X,Y,...)
    read -a z <<<"$2"
    for x in ${1}; do [ ${x:-0} -gt ${z[$((y++))]:-0} ] && gt=1; done
    if [ "$gt" ]; then echo "$1"
                  else echo "$2"; fi
}

CLANG_VERSION=$(package_max_version $CLANG_PREFIX)
if [ -z "$CLANG_VERSION" ] ; then
  echo >&2 "ERROR - no Clang compiler found among installed irods-externals*"
  exit 2
fi
LLVM_VERSION=$(echo "$CLANG_VERSION" | sed 's/[-.]/./g')

LIBCXX_PRETTY_PRINTERS_COMMIT=${LLVM_TO_KOUTHEIR_VERSION_LOOKUP[$LLVM_VERSION]}

if [ -z "$LIBCXX_PRETTY_PRINTERS_COMMIT" ]; then
  echo >&2 "WARNING - no optimal version of libc++ Pretty-Printers found."
  echo >&2 "          Using the default branch"
fi

LATEST_CLANG_RUNTIME=$(package_max_version $CLANG_RUNTIME_PREFIX)

if [ -x /usr/bin/zypper ] ;then
  pkgtool=zypper # SuSE
elif [ -x /usr/bin/yum ]; then
  pkgtool=yum    # CentOS, RHEL
  yum install -y epel-release
else
  pkgtool=apt    # Debian, Ubuntu
  apt update
fi

# Need: 
#  - python so that GDB and RR can load pretty printers
#  - git to fetch LLVM source
#  - make to build debug libraries

${pkgtool} install -y make git python python3

# Build debug versions of stdc++ lib shared objects.

echo >&2 -e "\n--> Checking out llvm and building debug libraries for cxx and cxxabi.\n"

CMAKE_VERSION=$(package_max_version $CMAKE_PREFIX)

if [ -n "${CMAKE_VERSION}" ]; then
    cd ~ ; git clone http://github.com/llvm/llvm-project
    cd llvm-project && \
    git checkout llvmorg-${LLVM_VERSION} && \
    mkdir build && \
    cd build && \
    ${CMAKE_PREFIX}${CMAKE_VERSION}/bin/cmake \
        -G "Unix Makefiles"  -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" ../llvm && \
    make -j7 cxx cxxabi
else
    echo >&2 "Need at least one irods-externals-cmake* package installed"
    exit 1
fi

# backup existing shared objects and copy in the debug versions

echo >&2 -e "\n--> Writing debug shared objects.\n"
for SHLIB in lib/libc++*.so*; do
    for DIR in /opt/irods-externals/clang{,-runtime}${CLANG_VERSION}/; do
        [ -f "$DIR/$SHLIB" -o -L "$DIR/$SHLIB" ] && mv "$DIR/$SHLIB"{,.orig}
        cp -rp "$SHLIB" "$DIR"/lib/.
    done
done

# Install & configure pretty-printers

if [ -z "${LIBCXX_PRETTY_PRINTERS_COMMIT}" ]; then
    GIT_PPRINTER_CHECKOUT_CMD=":"
else
    GIT_PPRINTER_CHECKOUT_CMD="git checkout '${LIBCXX_PRETTY_PRINTERS_COMMIT}'"
fi

echo >&2 -e "\n--> Creating $HOME/.gdbinit for gdb and rr.\n"
cd ~ ; git clone https://github.com/koutheir/libcxx-pretty-printers
cd libcxx-pretty-printers && eval "$GIT_PPRINTER_CHECKOUT_CMD"
PP_SRC_DIR=~/libcxx-pretty-printers/src
cp $PP_SRC_DIR/gdbinit ~/.gdbinit && sed -i -e "s@<path.*>@$PP_SRC_DIR@" ~/.gdbinit

