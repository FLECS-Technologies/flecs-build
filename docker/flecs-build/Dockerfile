FROM debian:buster-slim AS boost-downloader

COPY utils/docker/scripts/debian/install-packages.sh /tmp/

RUN /tmp/install-packages.sh ca-certificates wget

RUN wget -qO- https://boostorg.jfrog.io/artifactory/main/release/1.82.0/source/boost_1_82_0.tar.gz |\
    tar -C /opt -xz boost_1_82_0/boost boost_1_82_0/LICENSE_1_0.txt

RUN ln -snf /opt/boost_1_82_0/ /opt/boost

FROM debian:buster-slim

COPY --from=boost-downloader /opt /opt

RUN dpkg --add-architecture arm64
RUN dpkg --add-architecture armhf

ADD fs/ /

COPY utils/docker/scripts/debian/install-packages.sh /tmp/

RUN /tmp/install-packages.sh automake bc build-essential ca-certificates \
    cmake/buster-backports curl g++-aarch64-linux-gnu g++-arm-linux-gnueabihf \
    gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcovr git gnupg \
    libtool libudev-dev libudev-dev:arm64 libudev-dev:armhf lsb-release \
    ninja-build pkg-config udev wget xxd

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]\
    https://download.docker.com/linux/debian buster stable" >\
    /etc/apt/sources.list.d/docker.list

RUN /tmp/install-packages.sh docker-ce docker-ce-cli docker-buildx-plugin containerd.io

RUN (curl -sSf https://sh.rustup.rs | bash -s -- -y) && /root/.cargo/bin/rustup toolchain uninstall stable-x86_64-unknown-linux-gnu
