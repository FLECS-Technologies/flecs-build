# Copyright 2021-2024 FLECS Technologies GmbH
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

FROM rust:slim-bookworm AS flecs-build-rs

RUN dpkg --add-architecture arm64
RUN dpkg --add-architecture armhf

# Install necessary packages
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    cmake g++ g++-arm-linux-gnueabihf g++-aarch64-linux-gnu git ninja-build && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --system --add safe.directory "*"

RUN git clone https://github.com/FLECS-Technologies/flecs-build.git /usr/src/flecs-build

# cargo-semver-checks (or its dependencies) require make for installation
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
    make && \
    apt-get --yes clean && \
    rm -rf /var/lib/apt/lists/*

# Cargo components
RUN rustup component add rustfmt
RUN rustup component add clippy
RUN rustup component add llvm-tools-preview

# Coverage - cargo-llvm-cov
RUN cargo install cargo-llvm-cov --locked --version 0.6.6

# SemVer checks - cargo-semver-checks
RUN cargo install cargo-semver-checks --locked --version 0.29.1

# Vulnerability checks - cargo-audit
RUN cargo install cargo-audit --locked --version 0.20.0

# x86_64-linux-gnu
FROM flecs-build-rs AS flecs-build-rs-amd64
ENV RUSTFLAGS="-Clinker=x86_64-linux-gnu-gcc -Car=x86_64-linux-gnu-ar"
RUN rustup target add x86_64-unknown-linux-gnu

# aarch64-linux-gnu
FROM flecs-build-rs AS flecs-build-rs-arm64
ENV RUSTFLAGS="-Clinker=aarch64-linux-gnu-gcc -Car=aarch64-linux-gnu-ar"
RUN rustup target add aarch64-unknown-linux-gnu

# arm-linux-gnueabihf
FROM flecs-build-rs AS flecs-build-rs-armhf
ENV RUSTFLAGS="-Clinker=arm-linux-gnueabihf-gcc -Car=arm-linux-gnueabihf-ar"
RUN rustup target add armv7-unknown-linux-gnueabihf