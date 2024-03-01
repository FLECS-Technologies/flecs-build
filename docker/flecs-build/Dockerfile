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
FROM debian:bookworm-slim AS stage-1

RUN dpkg --add-architecture arm64
RUN dpkg --add-architecture armhf

RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    ca-certificates curl cmake g++ g++-arm-linux-gnueabihf g++-aarch64-linux-gnu git libudev-dev libudev-dev:arm64 libudev-dev:armhf ninja-build && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --system --add safe.directory "*"

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

# ------------------------------------------------------------------------------
# Stage 1 dependencies / self-contained
# Boost ------------------------------------------------------------------------
FROM stage-1 AS external-boost

RUN curl -fsSL -O https://boostorg.jfrog.io/artifactory/main/release/1.84.0/source/boost_1_84_0.tar.gz

RUN mkdir -p /usr/local/include/x86_64-linux-gnu && \
    tar -C /usr/local/include/x86_64-linux-gnu -xf boost_1_84_0.tar.gz --strip-components 1 \
    boost_1_84_0/boost
RUN mkdir -p /usr/local/share/doc/boost && \
    tar -C /usr/local/share/doc/boost -xf boost_1_84_0.tar.gz --strip-components 1 \
    boost_1_84_0/LICENSE_1_0.txt
RUN mkdir -p /usr/local/include/arm-linux-gnueabihf && ln -s /usr/local/include/x86_64-linux-gnu/boost /usr/local/include/arm-linux-gnueabihf/boost
RUN mkdir -p /usr/local/include/aarch64-linux-gnu && ln -s /usr/local/include/x86_64-linux-gnu/boost /usr/local/include/aarch64-linux-gnu/boost

# crow -------------------------------------------------------------------------
FROM stage-1 AS external-crow
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    patch && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -O https://github.com/CrowCpp/Crow/releases/download/v1.0%2B5/crow-v1.0+5.tar.gz
RUN mkdir -p /tmp/crow && tar -C /tmp/crow -xf crow-v1.0+5.tar.gz
RUN mkdir -p /usr/local/include/x86_64-linux-gnu && cp -prT /tmp/crow/include /usr/local/include/x86_64-linux-gnu
RUN mkdir -p /usr/local/include/arm-linux-gnueabihf && ln -s /usr/local/include/x86_64-linux-gnu/crow   /usr/local/include/arm-linux-gnueabihf/crow
RUN mkdir -p /usr/local/include/arm-linux-gnueabihf && ln -s /usr/local/include/x86_64-linux-gnu/crow.h /usr/local/include/arm-linux-gnueabihf/crow.h
RUN mkdir -p /usr/local/include/aarch64-linux-gnu && ln -s /usr/local/include/x86_64-linux-gnu/crow   /usr/local/include/aarch64-linux-gnu/crow
RUN mkdir -p /usr/local/include/aarch64-linux-gnu && ln -s /usr/local/include/x86_64-linux-gnu/crow.h /usr/local/include/aarch64-linux-gnu/crow.h
ADD patches/crow/ /tmp/
RUN cd /usr/local/include/x86_64-linux-gnu && patch -p 1 -i /tmp/*.patch

# googletest -------------------------------------------------------------------
FROM stage-1 AS googletest-downloader
RUN curl -fsSL -O https://github.com/google/googletest/archive/refs/tags/v1.14.0.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf v1.14.0.tar.gz
WORKDIR /usr/src/googletest-1.14.0
# x86_64-linux-gnu
FROM googletest-downloader AS googletest-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64}
RUN cmake --build build/
RUN cmake --install build/
# aarch64-linux-gnu
FROM googletest-downloader AS googletest-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64}
RUN cmake --build build/
RUN cmake --install build/
# arm-linux-gnueabihf
FROM googletest-downloader AS googletest-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF}
RUN cmake --build build/
RUN cmake --install build/
# install
FROM stage-1 AS external-googletest
COPY --from=googletest-build-amd64 /usr/local/include /usr/local/include
COPY --from=googletest-build-arm64 /usr/local/include /usr/local/include
COPY --from=googletest-build-armhf /usr/local/include /usr/local/include
COPY --from=googletest-build-amd64 /usr/local/lib /usr/local/lib
COPY --from=googletest-build-arm64 /usr/local/lib /usr/local/lib
COPY --from=googletest-build-armhf /usr/local/lib /usr/local/lib

# json -------------------------------------------------------------------------
FROM stage-1 as json-downloader
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    dirmngr gpg gpg-agent xz-utils && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -O https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
RUN curl -fsSL -O https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz.asc
RUN gpg --keyserver 'hkps://keyserver.ubuntu.com' --recv-keys '797167AE41C0A6D9232E48457F3CEA63AE251B69'
RUN gpg --verify json.tar.xz.asc json.tar.xz
RUN mkdir -p /usr/src && tar -C /usr/src -xf json.tar.xz
WORKDIR /usr/src/json
# x86_64-linux-gnu
FROM json-downloader AS json-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64} -DJSON_BuildTests=NO
RUN cmake --build build/
RUN cmake --install build/
# aarch64-linux-gnu
FROM json-downloader AS json-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64} -DJSON_BuildTests=NO
RUN cmake --build build/
RUN cmake --install build/
# arm-linux-gnueabihf
FROM json-downloader AS json-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF} -DJSON_BuildTests=NO
RUN cmake --build build/
RUN cmake --install build/
# install
FROM stage-1 AS external-json
COPY --from=json-build-amd64 /usr/local/include /usr/local/include
COPY --from=json-build-arm64 /usr/local/include /usr/local/include
COPY --from=json-build-armhf /usr/local/include /usr/local/include
COPY --from=json-build-armhf /usr/local/share /usr/local/share

# libusb -----------------------------------------------------------------------
FROM stage-1-make AS libusb-downloader
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    dirmngr gpg gpg-agent lbzip2 && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -O https://github.com/libusb/libusb/releases/download/v1.0.27/libusb-1.0.27.tar.bz2
RUN curl -fsSL -O https://github.com/libusb/libusb/releases/download/v1.0.27/libusb-1.0.27.tar.bz2.asc
RUN gpg --keyserver 'hkps://keyserver.ubuntu.com' --recv-keys 'C68187379B23DE9EFC46651E2C80FF56C6830A0E'
RUN gpg --verify libusb-1.0.27.tar.bz2.asc libusb-1.0.27.tar.bz2
RUN mkdir -p /usr/src && tar -C /usr/src -xf libusb-1.0.27.tar.bz2
WORKDIR /usr/src/libusb-1.0.27
# x86_64-linux-gnu
FROM libusb-downloader AS libusb-build-amd64
RUN ./configure --prefix=/usr/local --includedir=/usr/local/include/x86_64-linux-gnu --libdir=/usr/local/lib/x86_64-linux-gnu --host=x86_64-linux-gnu --enable-static=no
RUN make -j16 all && make install-strip
# aarch64-linux-gnu
FROM libusb-downloader AS libusb-build-arm64
RUN ./configure --prefix=/usr/local --includedir=/usr/local/include/aarch64-linux-gnu --libdir=/usr/local/lib/aarch64-linux-gnu --host=aarch64-linux-gnu  --enable-static=no
RUN make -j16 all && make install-strip
# arm-linux-gnueabihf
FROM libusb-downloader AS libusb-build-armhf
RUN ./configure --prefix=/usr/local --includedir=/usr/local/include/arm-linux-gnueabihf --libdir=/usr/local/lib/arm-linux-gnueabihf --host=arm-linux-gnueabihf  --enable-static=no
RUN make -j16 all && make install-strip
# install
FROM stage-1 AS external-libusb
COPY --from=libusb-build-amd64 /usr/local/include /usr/local/include
COPY --from=libusb-build-arm64 /usr/local/include /usr/local/include
COPY --from=libusb-build-armhf /usr/local/include /usr/local/include
COPY --from=libusb-build-amd64 /usr/local/lib /usr/local/lib
COPY --from=libusb-build-arm64 /usr/local/lib /usr/local/lib
COPY --from=libusb-build-armhf /usr/local/lib /usr/local/lib

# OpenSSL ----------------------------------------------------------------------
FROM stage-1-make AS openssl-downloader
RUN curl -fsSL -O https://www.openssl.org/source/openssl-3.2.1.tar.gz
RUN curl -fsSL -O https://www.openssl.org/source/openssl-3.2.1.tar.gz.sha256
RUN echo "$(cat openssl-3.2.1.tar.gz.sha256) openssl-3.2.1.tar.gz" | sha256sum --check --status
RUN mkdir -p /usr/src && tar -C /usr/src -xf openssl-3.2.1.tar.gz
WORKDIR /usr/src/openssl-3.2.1
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

# yaml-cpp ---------------------------------------------------------------------
FROM stage-1 AS yaml-cpp-downloader
RUN curl -fsSL -O https://github.com/jbeder/yaml-cpp/archive/refs/tags/0.8.0.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf 0.8.0.tar.gz
WORKDIR /usr/src/yaml-cpp-0.8.0
# x86_64-linux-gnu
FROM yaml-cpp-downloader AS yaml-cpp-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64} -DYAML_BUILD_SHARED_LIBS=Yes -DYAML_CPP_BUILD_TESTS=No
RUN cmake --build build/
RUN cmake --install build/
RUN [ "${BUILD_ENV}" = "Debug" ] && ln -s libyaml-cppd.so /usr/local/lib/x86_64-linux-gnu/libyaml-cpp.so || true
# aarch64-linux-gnu
FROM yaml-cpp-downloader AS yaml-cpp-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64} -DYAML_BUILD_SHARED_LIBS=Yes -DYAML_CPP_BUILD_TESTS=No
RUN cmake --build build/
RUN cmake --install build/
RUN [ "${BUILD_ENV}" = "Debug" ] && ln -s libyaml-cppd.so /usr/local/lib/aarch64-linux-gnu/libyaml-cpp.so || true
# arm-linux-gnueabihf
FROM yaml-cpp-downloader AS yaml-cpp-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF} -DYAML_BUILD_SHARED_LIBS=Yes -DYAML_CPP_BUILD_TESTS=No
RUN cmake --build build/
RUN cmake --install build/
RUN [ "${BUILD_ENV}" = "Debug" ] && ln -s libyaml-cppd.so /usr/local/lib/arm-linux-gnueabihf/libyaml-cpp.so || true
# install
FROM stage-1 AS external-yaml-cpp
COPY --from=yaml-cpp-build-amd64 /usr/local/include /usr/local/include
COPY --from=yaml-cpp-build-arm64 /usr/local/include /usr/local/include
COPY --from=yaml-cpp-build-armhf /usr/local/include /usr/local/include
COPY --from=yaml-cpp-build-amd64 /usr/local/lib /usr/local/lib
COPY --from=yaml-cpp-build-arm64 /usr/local/lib /usr/local/lib
COPY --from=yaml-cpp-build-armhf /usr/local/lib /usr/local/lib

# zenoh-c
FROM stage-1 AS zenoh-c-downloader
SHELL ["/bin/bash", "-c"]
RUN (curl -sSf https://sh.rustup.rs | bash -s -- -y)
ENV PATH="${PATH}:/root/.cargo/bin"
RUN curl -fsSL -O https://github.com/eclipse-zenoh/zenoh-c/archive/refs/tags/0.10.0-rc.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf 0.10.0-rc.tar.gz
WORKDIR /usr/src/zenoh-c-0.10.0-rc
# x86_64-linux-gnu
FROM zenoh-c-downloader AS zenoh-c-build-amd64
ENV RUSTFLAGS="-Clinker=x86_64-linux-gnu-gcc -Car=x86_64-linux-gnu-ar"
RUN rustup target add --toolchain stable x86_64-unknown-linux-gnu
RUN cmake ${CMAKE_ARGS_AMD64} -DZENOHC_CUSTOM_TARGET="x86_64-unknown-linux-gnu"
RUN cmake --build build/
RUN cmake --install build/
# aarch64-linux-gnu
FROM zenoh-c-downloader AS zenoh-c-build-arm64
ENV RUSTFLAGS="-Clinker=aarch64-linux-gnu-gcc -Car=aarch64-linux-gnu-ar"
RUN rustup target add --toolchain stable aarch64-unknown-linux-gnu
RUN cmake ${CMAKE_ARGS_ARM64} -DZENOHC_CUSTOM_TARGET="aarch64-unknown-linux-gnu"
RUN cmake --build build/
RUN cmake --install build/
# arm-linux-gnueabihf
FROM zenoh-c-downloader AS zenoh-c-build-armhf
ENV RUSTFLAGS="-Clinker=arm-linux-gnueabihf-gcc -Car=arm-linux-gnueabihf-ar"
RUN rustup target add --toolchain stable armv7-unknown-linux-gnueabihf
RUN cmake ${CMAKE_ARGS_ARMHF} -DZENOHC_CUSTOM_TARGET="armv7-unknown-linux-gnueabihf"
RUN cmake --build build/
RUN cmake --install build/
# install
FROM stage-1 AS external-zenoh-c
COPY --from=zenoh-c-build-amd64 /usr/local/include /usr/local/include
COPY --from=zenoh-c-build-arm64 /usr/local/include /usr/local/include
COPY --from=zenoh-c-build-armhf /usr/local/include /usr/local/include
COPY --from=zenoh-c-build-amd64 /usr/local/lib /usr/local/lib
COPY --from=zenoh-c-build-arm64 /usr/local/lib /usr/local/lib
COPY --from=zenoh-c-build-armhf /usr/local/lib /usr/local/lib

# zlib -------------------------------------------------------------------------
FROM stage-1 AS zlib-downloader
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    dirmngr gpg gpg-agent && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -O https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
RUN curl -fsSL -O https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz.asc
RUN gpg --keyserver 'hkps://keyserver.ubuntu.com' --recv-keys '5ED46A6721D365587791E2AA783FCD8E58BCAFBA'
RUN gpg --verify zlib-1.3.1.tar.gz.asc zlib-1.3.1.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf zlib-1.3.1.tar.gz
WORKDIR /usr/src/zlib-1.3.1
# x86_64-linux-gnu
FROM zlib-downloader AS zlib-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64} -DINSTALL_INC_DIR=/usr/local/include/x86_64-linux-gnu -DINSTALL_LIB_DIR=/usr/local/lib/x86_64-linux-gnu -DINSTALL_BIN_DIR=usr/local/bin/x86_64-linux-gnu
RUN cmake --build build/
RUN cmake --install build/
RUN find /usr/local/ -name "libz.a" -exec rm {} \;
# aarch64-linux-gnu
FROM zlib-downloader AS zlib-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64} -DINSTALL_INC_DIR=/usr/local/include/aarch64-linux-gnu -DINSTALL_LIB_DIR=/usr/local/lib/aarch64-linux-gnu -DINSTALL_BIN_DIR=usr/local/bin/aarch64-linux-gnu
RUN cmake --build build/
RUN cmake --install build/
RUN find /usr/local/ -name "libz.a" -exec rm {} \;
# arm-linux-gnueabihf
FROM zlib-downloader AS zlib-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF} -DINSTALL_INC_DIR=/usr/local/include/arm-linux-gnueabihf -DINSTALL_LIB_DIR=/usr/local/lib/arm-linux-gnueabihf -DINSTALL_BIN_DIR=usr/local/bin/arm-linux-gnueabihf
RUN cmake --build build/
RUN cmake --install build/
RUN find /usr/local/ -name "libz.a" -exec rm {} \;
# install
FROM stage-1 AS external-zlib
COPY --from=zlib-build-amd64 /usr/local/include /usr/local/include
COPY --from=zlib-build-arm64 /usr/local/include /usr/local/include
COPY --from=zlib-build-armhf /usr/local/include /usr/local/include
COPY --from=zlib-build-amd64 /usr/local/lib /usr/local/lib
COPY --from=zlib-build-arm64 /usr/local/lib /usr/local/lib
COPY --from=zlib-build-armhf /usr/local/lib /usr/local/lib

# ------------------------------------------------------------------------------
# Stage 2 dependencies / dependent on stage 1 libs (mainly OpenSSL)
FROM stage-1 AS stage-2
COPY --from=external-openssl /usr/local/ /usr/local/
# curl -------------------------------------------------------------------------
FROM stage-2 AS curl-downloader
COPY --from=external-zlib /usr/local/ /usr/local/
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    dirmngr gpg gpg-agent && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -O https://github.com/curl/curl/releases/download/curl-8_6_0/curl-8.6.0.tar.gz
RUN curl -fsSL -O https://github.com/curl/curl/releases/download/curl-8_6_0/curl-8.6.0.tar.gz.asc
RUN gpg --keyserver 'hkps://keyserver.ubuntu.com' --recv-keys '27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2'
RUN gpg --verify curl-8.6.0.tar.gz.asc curl-8.6.0.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf curl-8.6.0.tar.gz
WORKDIR /usr/src/curl-8.6.0
# x86_64-linux-gnu
FROM curl-downloader AS curl-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64} -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu -DCMAKE_INSTALL_BINDIR=bin/x86_64-linux-gnu -DCMAKE_INSTALL_INCLUDEDIR=include/x86_64-linux-gnu -DCURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt -DBUILD_CURL_EXE=NO
RUN cmake --build build/
RUN cmake --install build/
RUN [ "${BUILD_ENV}" = "Debug" ] && ln -s libcurl-d.so /usr/local/lib/x86_64-linux-gnu/libcurl.so || true
# aarch64-linux-gnu
FROM curl-downloader AS curl-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64} -DCMAKE_INSTALL_LIBDIR=lib/aarch64-linux-gnu -DCMAKE_INSTALL_BINDIR=bin/aarch64-linux-gnu -DCMAKE_INSTALL_INCLUDEDIR=include/aarch64-linux-gnu -DCURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt -DBUILD_CURL_EXE=NO
RUN cmake --build build/
RUN cmake --install build/
RUN [ "${BUILD_ENV}" = "Debug" ] && ln -s libcurl-d.so /usr/local/lib/aarch64-linux-gnu/libcurl.so || true
# arm-linux-gnueabihf
FROM curl-downloader AS curl-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF} -DCMAKE_INSTALL_LIBDIR=lib/arm-linux-gnueabihf -DCMAKE_INSTALL_BINDIR=bin/arm-linux-gnueabihf -DCMAKE_INSTALL_INCLUDEDIR=include/arm-linux-gnueabihf -DCURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt -DBUILD_CURL_EXE=NO
RUN cmake --build build/
RUN cmake --install build/
RUN [ "${BUILD_ENV}" = "Debug" ] && ln -s libcurl-d.so /usr/local/lib/arm-linux-gnueabihf/libcurl.so || true
# install
FROM stage-1 AS external-curl
COPY --from=curl-build-amd64 /usr/local/include/ /usr/local/include/
COPY --from=curl-build-arm64 /usr/local/include/ /usr/local/include/
COPY --from=curl-build-armhf /usr/local/include/ /usr/local/include/
COPY --from=curl-build-amd64 /usr/local/lib/ /usr/local/lib/
COPY --from=curl-build-arm64 /usr/local/lib/ /usr/local/lib/
COPY --from=curl-build-armhf /usr/local/lib/ /usr/local/lib/
COPY --from=curl-build-amd64 /usr/local/bin/ /usr/local/bin/
COPY --from=curl-build-arm64 /usr/local/bin/ /usr/local/bin/
COPY --from=curl-build-armhf /usr/local/bin/ /usr/local/bin/

# libarchive -------------------------------------------------------------------
FROM stage-2 AS libarchive-downloader
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    dirmngr gpg gpg-agent && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -O https://github.com/libarchive/libarchive/releases/download/v3.7.2/libarchive-3.7.2.tar.gz
RUN curl -fsSL -O https://github.com/libarchive/libarchive/releases/download/v3.7.2/libarchive-3.7.2.tar.gz.asc
RUN gpg --keyserver 'hkps://keyserver.ubuntu.com' --recv-keys 'DB2C7CF1B4C265FAEF56E3FC5848A18B8F14184B'
RUN gpg --verify libarchive-3.7.2.tar.gz.asc libarchive-3.7.2.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf libarchive-3.7.2.tar.gz
WORKDIR /usr/src/libarchive-3.7.2
# x86_64-linux-gnu
FROM libarchive-downloader AS libarchive-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64} -DENABLE_LIBXML2=OFF -DENABLE_EXPAT=OFF
RUN cmake --build build/
RUN cmake --install build/
RUN find /usr/local/ -name "libarchive.a" -exec rm {} \;
# aarch64-linux-gnu
FROM libarchive-downloader AS libarchive-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64} -DENABLE_LIBXML2=OFF -DENABLE_EXPAT=OFF
RUN cmake --build build/
RUN cmake --install build/
RUN find /usr/local/ -name "libarchive.a" -exec rm {} \;
# arm-linux-gnueabihf
FROM libarchive-downloader AS libarchive-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF} -DENABLE_LIBXML2=OFF -DENABLE_EXPAT=OFF
RUN cmake --build build/
RUN cmake --install build/
RUN find /usr/local/ -name "libarchive.a" -exec rm {} \;
# install
FROM stage-1 AS external-libarchive
COPY --from=libarchive-build-amd64 /usr/local/include/*.h /usr/local/include/x86_64-linux-gnu/
COPY --from=libarchive-build-arm64 /usr/local/include/*.h /usr/local/include/aarch64-linux-gnu/
COPY --from=libarchive-build-armhf /usr/local/include/*.h /usr/local/include/arm-linux-gnueabihf/
COPY --from=libarchive-build-amd64 /usr/local/lib/*.so* /usr/local/lib/x86_64-linux-gnu/
COPY --from=libarchive-build-arm64 /usr/local/lib/*.so* /usr/local/lib/aarch64-linux-gnu/
COPY --from=libarchive-build-armhf /usr/local/lib/*.so* /usr/local/lib/arm-linux-gnueabihf/

# mosquitto --------------------------------------------------------------------
FROM stage-2 AS mosquitto-downloader
RUN curl -fsSL -O https://github.com/eclipse/mosquitto/archive/refs/tags/v2.0.18.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf v2.0.18.tar.gz
WORKDIR /usr/src/mosquitto-2.0.18
# x86_64-linux-gnu
FROM mosquitto-downloader AS mosquitto-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64} -DDOCUMENTATION=NO -DWITH_STATIC_LIBRARIES=NO -DWITH_PIC=YES -DWITH_APPS=NO -DWITH_BROKER=NO -DWITH_CLIENTS=NO -DWITH_PLUGINS=NO -DWITH_LIB_CPP=NO
RUN cmake --build build/
RUN cmake --install build/
# aarch64-linux-gnu
FROM mosquitto-downloader AS mosquitto-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64} -DDOCUMENTATION=NO -DWITH_STATIC_LIBRARIES=NO -DWITH_PIC=YES -DWITH_APPS=NO -DWITH_BROKER=NO -DWITH_CLIENTS=NO -DWITH_PLUGINS=NO -DWITH_LIB_CPP=NO
RUN cmake --build build/
RUN cmake --install build/
# arm-linux-gnueabihf
FROM mosquitto-downloader AS mosquitto-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF} -DDOCUMENTATION=NO -DWITH_STATIC_LIBRARIES=NO -DWITH_PIC=YES -DWITH_APPS=NO -DWITH_BROKER=NO -DWITH_CLIENTS=NO -DWITH_PLUGINS=NO -DWITH_LIB_CPP=NO
RUN cmake --build build/
RUN cmake --install build/
# install
FROM stage-1 AS external-mosquitto
COPY --from=mosquitto-build-amd64 /usr/local/include /usr/local/include
COPY --from=mosquitto-build-arm64 /usr/local/include /usr/local/include
COPY --from=mosquitto-build-armhf /usr/local/include /usr/local/include
COPY --from=mosquitto-build-amd64 /usr/local/lib /usr/local/lib
COPY --from=mosquitto-build-arm64 /usr/local/lib /usr/local/lib
COPY --from=mosquitto-build-armhf /usr/local/lib /usr/local/lib

# ------------------------------------------------------------------------------
# Stage 3 dependencies / dependent on stage 2 libs
# cpr --------------------------------------------------------------------------
FROM stage-2 AS cpr-downloader
COPY --from=external-curl /usr/local/ /usr/local/
COPY --from=external-zlib /usr/local/ /usr/local/
RUN curl -fsSL -O https://github.com/libcpr/cpr/archive/refs/tags/1.10.5.tar.gz
RUN mkdir -p /usr/src && tar -C /usr/src -xf 1.10.5.tar.gz
WORKDIR /usr/src/cpr-1.10.5
# x86_64-linux-gnu
FROM cpr-downloader AS cpr-build-amd64
RUN cmake ${CMAKE_ARGS_AMD64} -DCPR_BUILD_TESTS=NO -DCPR_USE_SYSTEM_CURL=YES
RUN cmake --build build/
RUN cmake --install build/
# aarch64-linux-gnu
FROM cpr-downloader AS cpr-build-arm64
RUN cmake ${CMAKE_ARGS_ARM64} -DCPR_BUILD_TESTS=NO -DCPR_USE_SYSTEM_CURL=YES
RUN cmake --build build/
RUN cmake --install build/
# arm-linux-gnueabihf
FROM cpr-downloader AS cpr-build-armhf
RUN cmake ${CMAKE_ARGS_ARMHF} -DCPR_BUILD_TESTS=NO -DCPR_USE_SYSTEM_CURL=YES
RUN cmake --build build/
RUN cmake --install build/
# install
FROM stage-1 AS external-cpr
COPY --from=cpr-build-amd64 /usr/local/include /usr/local/include
COPY --from=cpr-build-arm64 /usr/local/include /usr/local/include
COPY --from=cpr-build-armhf /usr/local/include /usr/local/include
COPY --from=cpr-build-amd64 /usr/local/lib /usr/local/lib
COPY --from=cpr-build-arm64 /usr/local/lib /usr/local/lib
COPY --from=cpr-build-armhf /usr/local/lib /usr/local/lib

FROM stage-1 AS docker-downloader

RUN curl -fsSL --output - https://download.docker.com/linux/static/stable/x86_64/docker-25.0.3.tgz |\
    tar -C /usr/local/bin --strip-components=1 -xzf - docker/docker && \
    chown root:root /usr/local/bin/docker

FROM stage-1 AS flecs-build

# additional packages required for building and running tests
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    fakeroot gcovr pkg-config pkg-config:armhf pkg-config:arm64 udev && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ~/.docker/cli-plugins && \
    curl -L -o ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-amd64 &&\
    chmod a+x ~/.docker/cli-plugins/docker-buildx

# Stage 1
COPY --from=external-boost /usr/local/ /usr/local/
COPY --from=external-crow /usr/local/ /usr/local/
COPY --from=external-googletest /usr/local/ /usr/local/
COPY --from=external-json /usr/local/ /usr/local/
COPY --from=external-libusb /usr/local/ /usr/local/
COPY --from=external-openssl /usr/local/ /usr/local/
COPY --from=external-yaml-cpp /usr/local/ /usr/local/
COPY --from=external-zenoh-c /usr/local/ /usr/local/
COPY --from=external-zlib /usr/local/ /usr/local/
# Stage 2
COPY --from=external-curl /usr/local/ /usr/local/
COPY --from=external-libarchive /usr/local/ /usr/local/
COPY --from=external-mosquitto /usr/local/ /usr/local/
# Stage 3
COPY --from=external-cpr /usr/local/ /usr/local/
# Run ldconfig
RUN echo "/lib/x86_64-linux-gnu\n/usr/lib/x86_64-linux-gnu\n/usr/local/lib/x86_64-linux-gnu" >/etc/ld.so.conf.d/x86_64-linux-gnu.conf && ldconfig
# Docker
COPY --from=docker-downloader /usr/local/bin/docker /usr/local/bin
