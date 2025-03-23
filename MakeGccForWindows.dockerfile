FROM ubuntu:20.04 AS builder

# Set environment variable to make the installation non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    xz-utils \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    texinfo \
    mingw-w64 \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV CORES=16
ENV DISTCLEAN=0
ENV GCC_VERSION=14.2.0
ENV BINUTILS_VERSION=2.44
ENV GCC_CONFIGURE_OPTIONS="\
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
    --disable-libcc1"
ENV BINUTILS_CONFIGURE_OPTIONS="\
    --disable-nls \
    --enable-multilib \
    --disable-werror"

ARG TARGET
ENV TARGET=${TARGET}

# Set the working directory
WORKDIR /workspace

# Create a volume to share the /workspace directory with the host
VOLUME ["/workspace"]

# Copy the build script into the container
COPY create_gcc.sh /create_gcc.sh
# Copy the Canadian Cross build script into the container
COPY create_canadian_cross_gcc.sh /create_canadian_cross_gcc.sh
# Copy the toolchain template into the container
COPY toolchain_template.cmake /toolchain_template.cmake
# Copy the create cmake toolchain script into the container
COPY create_cmake_toolchain.sh /create_cmake_toolchain.sh

# Make the script executable
RUN chmod +x /create_gcc.sh
# Make the Canadian Cross build script executable
RUN chmod +x /create_canadian_cross_gcc.sh
# Make the create cmake toolchain script executable
RUN chmod +x /create_cmake_toolchain.sh

# Run the build script
ENTRYPOINT ["/bin/bash", "-c", "/create_gcc.sh && /create_canadian_cross_gcc.sh"]