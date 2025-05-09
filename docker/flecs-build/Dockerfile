# Copyright 2021-2023 FLECS Technologies GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# flecs/flecs-build: Universal Docker image to build FLECS and all of its dependencies.
#
# Common grounds to start from. Clean Debian 12 with essential tools for building , i.e.
#   - curl / ca-certificates to download 3rd party dependencies
#   - CMake / Ninja
#   - cross-platform compilers
#   - flecs-build repository providing common CMake modules
#   - rustup with toolchains for cross-compiling
FROM debian:bookworm-slim AS stage-1

RUN dpkg --add-architecture arm64
RUN dpkg --add-architecture armhf

RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    ca-certificates curl cmake g++ g++-arm-linux-gnueabihf g++-aarch64-linux-gnu git libudev-dev libudev-dev:arm64 libudev-dev:armhf ninja-build pkg-config && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --system --add safe.directory "*"

ENV FLECS_DEFAULT_RUST_TOOLCHAIN_VERSION="1.86.0"
ENV FLECS_DEFAULT_RUST_TOOLCHAIN="${FLECS_DEFAULT_RUST_TOOLCHAIN_VERSION}-x86_64-unknown-linux-gnu"
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
RUN (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain ${FLECS_DEFAULT_RUST_TOOLCHAIN})
ENV PATH="${PATH}:${CARGO_HOME}/bin"
RUN rustup target add --toolchain ${FLECS_DEFAULT_RUST_TOOLCHAIN} x86_64-unknown-linux-gnu
RUN rustup target add --toolchain ${FLECS_DEFAULT_RUST_TOOLCHAIN} aarch64-unknown-linux-gnu
RUN rustup target add --toolchain ${FLECS_DEFAULT_RUST_TOOLCHAIN} armv7-unknown-linux-gnueabihf
RUN rustup component add clippy
RUN rustup component add rustfmt
RUN rustup component add llvm-tools-preview
RUN cargo install --version 0.6.15 cargo-llvm-cov

RUN git clone https://github.com/FLECS-Technologies/flecs-build.git /usr/src/flecs-build

WORKDIR /tmp

ARG FLECS_DEBUG

ENV BUILD_ENV=${FLECS_DEBUG:+Debug}
ENV BUILD_ENV=${BUILD_ENV:-Release}

ENV PATH="${PATH}:/usr/local/bin/x86_64-linux-gnu"
ENV CMAKE_ARGS_COMMON="-G Ninja -B build -DCMAKE_CXX_STANDARD=20 -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_BUILD_TYPE=${BUILD_ENV} -DCMAKE_INSTALL_PREFIX=/usr/local"
ENV CMAKE_ARGS_AMD64="${CMAKE_ARGS_COMMON} -DCMAKE_INSTALL_INCLUDEDIR=include/x86_64-linux-gnu    -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu    -DCMAKE_INSTALL_BINDIR=bin/x86_64-linux-gnu    -DCMAKE_TOOLCHAIN_FILE=/usr/src/flecs-build/cmake/toolchains/amd64.cmake"
ENV CMAKE_ARGS_ARM64="${CMAKE_ARGS_COMMON} -DCMAKE_INSTALL_INCLUDEDIR=include/aarch64-linux-gnu   -DCMAKE_INSTALL_LIBDIR=lib/aarch64-linux-gnu   -DCMAKE_INSTALL_BINDIR=bin/aarch64-linux-gnu   -DCMAKE_TOOLCHAIN_FILE=/usr/src/flecs-build/cmake/toolchains/arm64.cmake"
ENV CMAKE_ARGS_ARMHF="${CMAKE_ARGS_COMMON} -DCMAKE_INSTALL_INCLUDEDIR=include/arm-linux-gnueabihf -DCMAKE_INSTALL_LIBDIR=lib/arm-linux-gnueabihf -DCMAKE_INSTALL_BINDIR=bin/arm-linux-gnueabihf -DCMAKE_TOOLCHAIN_FILE=/usr/src/flecs-build/cmake/toolchains/armhf.cmake"
ENV CARGO_PROFILE=${FLECS_DEBUG:+"--profile dev"}
ENV CARGO_PROFILE=${CARGO_PROFILE:-"--profile release"}

# Some externals require make, so setup an extended base containing make
FROM stage-1 AS stage-1-make
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    make && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*

# OpenSSL ----------------------------------------------------------------------
FROM stage-1-make AS openssl-downloader
RUN curl -fsSL -O https://www.openssl.org/source/openssl-3.4.0.tar.gz
RUN curl -fsSL -O https://www.openssl.org/source/openssl-3.4.0.tar.gz.sha256
RUN echo "$(cat openssl-3.4.0.tar.gz.sha256)" | sha256sum --check --status
RUN mkdir -p /usr/src && tar -C /usr/src -xf openssl-3.4.0.tar.gz
WORKDIR /usr/src/openssl-3.4.0
# x86_64-linux-gnu
FROM openssl-downloader AS openssl-build-amd64
RUN ./Configure linux-x86_64 --libdir=lib --cross-compile-prefix=x86_64-linux-gnu- --prefix=/usr/local shared
RUN make -j16 build_sw && make install_sw
RUN find /usr/local/ -name "*.a*" -exec rm {} \;
# aarch64-linux-gnu
FROM openssl-downloader AS openssl-build-arm64
RUN ./Configure linux-aarch64 --libdir=lib --cross-compile-prefix=aarch64-linux-gnu- --prefix=/usr/local shared
RUN make -j16 build_sw && make install_sw
RUN find /usr/local/ -name "*.a*" -exec rm {} \;
# arm-linux-gnueabihf
FROM openssl-downloader AS openssl-build-armhf
RUN ./Configure linux-armv4 -D__ARM_MAX_ARCH__=7 --libdir=lib --cross-compile-prefix=arm-linux-gnueabihf- --prefix=/usr/local shared
RUN make -j16 build_sw && make install_sw
RUN find /usr/local/ -name "*.a*" -exec rm {} \;
# install
FROM stage-1 AS external-openssl
COPY --from=openssl-build-amd64 /usr/local/include /usr/local/include/x86_64-linux-gnu/
COPY --from=openssl-build-arm64 /usr/local/include /usr/local/include/aarch64-linux-gnu/
COPY --from=openssl-build-armhf /usr/local/include /usr/local/include/arm-linux-gnueabihf/
COPY --from=openssl-build-amd64 /usr/local/lib /usr/local/lib/x86_64-linux-gnu/
COPY --from=openssl-build-arm64 /usr/local/lib /usr/local/lib/aarch64-linux-gnu/
COPY --from=openssl-build-armhf /usr/local/lib /usr/local/lib/arm-linux-gnueabihf/

FROM stage-1 AS docker-downloader

RUN curl -fsSL --output - https://download.docker.com/linux/static/stable/x86_64/docker-27.4.1.tgz |\
    tar -C /usr/local/bin --strip-components=1 -xzf - docker/docker && \
    chown root:root /usr/local/bin/docker

FROM stage-1 AS flecs-build

# additional packages required for building and running tests
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    fakeroot gcovr iproute2 udev && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ~/.docker/cli-plugins && \
    curl -L -o ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.19.3/buildx-v0.19.3.linux-amd64 &&\
    chmod a+x ~/.docker/cli-plugins/docker-buildx

# Stage 1
COPY --from=external-openssl /usr/local/ /usr/local/

# Run ldconfig
RUN echo "/lib/x86_64-linux-gnu\n/usr/lib/x86_64-linux-gnu\n/usr/local/lib/x86_64-linux-gnu" >/etc/ld.so.conf.d/x86_64-linux-gnu.conf && ldconfig
# Docker
COPY --from=docker-downloader /usr/local/bin/docker /usr/local/bin
# pkg-config variables required by Rust
ENV PKG_CONFIG_PATH_x86_64_unknown_linux_gnu="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig"
ENV PKG_CONFIG_PATH_aarch64_unknown_linux_gnu="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/aarch64-linux-gnu/pkgconfig"
ENV PKG_CONFIG_PATH_armv7_unknown_linux_gnueabihf="/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/arm-linux-gnueabihf/pkgconfig"

ENV PKG_CONFIG_LIBDIR_x86_64_unknown_linux_gnu="/usr/lib/x86_64-linux-gnu"
ENV PKG_CONFIG_LIBDIR_aarch64_unknown_linux_gnu="/usr/lib/aarch64-linux-gnu"
ENV PKG_CONFIG_LIBDIR_armv7_unknown_linux_gnueabihf="/usr/lib/arm-linux-gnueabihf"

ENV PKG_CONFIG_SYSROOT_DIR_x86_64_unknown_linux_gnu="/"
ENV PKG_CONFIG_SYSROOT_DIR_aarch64_unknown_linux_gnu="/"
ENV PKG_CONFIG_SYSROOT_DIR_armv7_unknown_linux_gnueabihf="/"
