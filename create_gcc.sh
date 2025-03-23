#!/bin/bash

# Define variables
GCC_VERSION=${GCC_VERSION:-"10.2.0"}
BINUTILS_VERSION=${BINUTILS_VERSION:-"2.35"}
TARGET=${TARGET:-"riscv64-unknown-elf"}
INSTALL_DIR="/opt/linux-${TARGET}-gcc"

GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz"
NUM_CORES=$(nproc)

echo ${TARGET} " toolchain build starting."

# Create necessary directories
mkdir -p ${INSTALL_DIR}
mkdir -p ${INSTALL_DIR}/src
mkdir -p ${INSTALL_DIR}/build

cd ${INSTALL_DIR}/src

# copy it from the workspace if it exists
if [ -f /workspace/binutils-${BINUTILS_VERSION}.tar.gz ]; then
    echo "Copying binutils-${BINUTILS_VERSION}.tar.gz from workspace"
    cp /workspace/binutils-${BINUTILS_VERSION}.tar.gz binutils-${BINUTILS_VERSION}.tar.gz
fi
if [ -f /workspace/gcc-${GCC_VERSION}.tar.gz ]; then
    echo "Copying gcc-${GCC_VERSION}.tar.gz from workspace"
    cp /workspace/gcc-${GCC_VERSION}.tar.gz gcc-${GCC_VERSION}.tar.gz
fi

# if not provided in the workspace, download the source
if [ ! -f binutils-${BINUTILS_VERSION}.tar.gz ]; then
    wget ${BINUTILS_URL}
    cp binutils-${BINUTILS_VERSION}.tar.gz /workspace/
fi
if [ ! -f gcc-${GCC_VERSION}.tar.gz ]; then
    wget ${GCC_URL}
    cp gcc-${GCC_VERSION}.tar.gz /workspace/
fi

# extract the source
if [ ! -d binutils-${BINUTILS_VERSION} ]; then
    tar -xzf binutils-${BINUTILS_VERSION}.tar.gz
fi
if [ ! -d gcc-${GCC_VERSION} ]; then
    tar -xzf gcc-${GCC_VERSION}.tar.gz
fi

# Download GCC prerequisites
cd ${INSTALL_DIR}/src/gcc-${GCC_VERSION}
./contrib/download_prerequisites

cd ${INSTALL_DIR}/src

# Build and install binutils
mkdir -p ${INSTALL_DIR}/build/binutils-build
cd ${INSTALL_DIR}/build/binutils-build
${INSTALL_DIR}/src/binutils-${BINUTILS_VERSION}/configure --target=${TARGET} --prefix=${INSTALL_DIR} --disable-nls --disable-werror
make -j${NUM_CORES}
make install

# Configure GCC
mkdir -p ${INSTALL_DIR}/build/gcc-build
cd ${INSTALL_DIR}/build/gcc-build
${INSTALL_DIR}/src/gcc-${GCC_VERSION}/configure --target=${TARGET} --prefix=${INSTALL_DIR} --disable-shared --disable-threads --disable-libmudflap --disable-libssp --disable-libgomp --disable-libquadmath --disable-libatomic --disable-libitm --disable-libvtv --enable-languages=c,c++ --without-newlib --disable-nls --disable-bootstrap --disable-multilib --disable-libstdcxx --with-headers --disable-libcc1

# Build and install GCC
make -j${NUM_CORES}
make install

# Zip up the results
cd ${INSTALL_DIR}
tar -czvf /tmp/linux-${TARGET}-gcc.tar.gz --exclude="build/*" --exclude="src/*" .

# Move the zip file to the workspace folder
mv /tmp/linux-${TARGET}-gcc.tar.gz /workspace/

echo ${TARGET} " toolchain installation completed."