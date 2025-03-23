#!/bin/bash

# this expects /opt/riscv/bin to be setup by create_gcc.sh

# Define variables
GCC_VERSION=${GCC_VERSION:-"10.2.0"}
BINUTILS_VERSION=${BINUTILS_VERSION:-"2.35"}

GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz"

TARGET=${TARGET:-"riscv64-unknown-elf"}
BUILD="x86_64-linux-gnu"
HOST="x86_64-w64-mingw32"

NUM_CORES=$(nproc)

INSTALL_DIR="/opt/win-${TARGET}-gcc"
LINUX_TARGET_DIR="/opt/linux-${TARGET}-gcc"

# Use the GCC_CONFIGURE_OPTIONS environment variable
GCC_CONFIGURE_OPTIONS=${GCC_CONFIGURE_OPTIONS:-"\
    --disable-shared \
    --disable-threads \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libatomic \
    --disable-libitm \
    --disable-libvtv \
    --enable-languages=c,c++ \
    --without-newlib \
    --disable-nls \
    --disable-bootstrap \
    --enable-multilib \
    --disable-libstdcxx \
    --with-headers \
    --disable-libcc1"}

# Use the BINUTILS_CONFIGURE_OPTIONS environment variable
BINUTILS_CONFIGURE_OPTIONS=${BINUTILS_CONFIGURE_OPTIONS:-"\
    --disable-nls \
    --enable-multilib \
    --disable-werror"}

echo "Windows Cross "${TARGET}" toolchain build starting."

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

# Add the linux toolchain to the PATH
export PATH=${LINUX_TARGET_DIR}/bin:$PATH

# Build and install binutils
mkdir -p ${INSTALL_DIR}/build/binutils-build
cd ${INSTALL_DIR}/build/binutils-build
${INSTALL_DIR}/src/binutils-${BINUTILS_VERSION}/configure --build=${BUILD} --host=${HOST} --target=${TARGET} --prefix=${INSTALL_DIR} ${BINUTILS_CONFIGURE_OPTIONS}
make -j${NUM_CORES}
make install

# Create build directory for GCC
# Configure GCC
mkdir -p ${INSTALL_DIR}/build/gcc-build
cd ${INSTALL_DIR}/build/gcc-build
${INSTALL_DIR}/src/gcc-${GCC_VERSION}/configure --build=${BUILD} --host=${HOST} --target=${TARGET} --prefix=${INSTALL_DIR} ${GCC_CONFIGURE_OPTIONS}

# Build and install GCC
make -j${NUM_CORES}
make install

# Zip up the results
cd ${INSTALL_DIR}
tar -czvf /tmp/win-${TARGET}-gcc.tar.gz --exclude="build/*" --exclude="src/*" .

# Move the zip file to the workspace folder
mv /tmp/win-${TARGET}-gcc.tar.gz /workspace/

echo "Windows Cross "${TARGET}" toolchain in win-"${TARGET}"-gcc.tar.gz"
