#!/bin/bash

[ $(id -u) = 0 ] || { echo "Please run this script as root." >&2; exit 1; }

if [ -x /usr/bin/zypper ] ;then
  pkgtool=zypper # SuSE
elif [ -x /usr/bin/yum ]; then
  pkgtool=yum    # CentOS, RHEL
  yum install -y epel-release
else
  pkgtool=apt    # Debian, Ubuntu
  apt update
fi

${pkgtool} install -y make git python python3

# Build debug versions of stdc++ lib shared objects.

echo >&2 -e "\n--> Checking out llvm and building debug libraries for cxx and cxxabi.\n"

cd ~ ; git clone http://github.com/llvm/llvm-project
cd llvm-project && \
    git checkout llvmorg-6.0.0 && \
    mkdir build && \
    cd build && \
    /opt/irods-externals/cmake3.11.4-0/bin/cmake \
        -G "Unix Makefiles"  -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" ../llvm && \
    make -j7 cxx cxxabi

# backup existing shared objects and copy in the debug versions

echo >&2 -e "\n--> Writing debug shared objects.\n"

for SHLIB in lib/libc++*.so*; do
    for DIR in /opt/irods-externals/clang{,-runtime}6.0-0/; do
        [ -f $DIR/$SHLIB -o -L $DIR/$SHLIB ] && mv $DIR/$SHLIB{,.orig}
        cp -rp $SHLIB $DIR/lib/.
    done
done

# Install & configure pretty-printers

echo >&2 -e "\n--> Creating $HOME/.gdbinit for gdb and rr.\n"

cd ~ ; git clone https://github.com/koutheir/libcxx-pretty-printers
cd libcxx-pretty-printers && git checkout "5ffbf2487bf8da7f08bc1c8650a4396d2ff15403"
PP_SRC_DIR=~/libcxx-pretty-printers/src
cp $PP_SRC_DIR/gdbinit ~/.gdbinit && sed -i -e "s@<path.*>@$PP_SRC_DIR@" ~/.gdbinit

