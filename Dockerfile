FROM --platform=linux/arm64/v8 debian@sha256:55cd39723a057f730e9c33487fea9fe151bbe86dce51e92a73ccfd12206a1f43

MAINTAINER simon987 <me@simon987.net>


RUN apt update

RUN DEBIAN_FRONTEND="noninteractive" apt install -y pkg-config python3 python3-pip \
	yasm ragel automake autotools-dev wget libtool libssl-dev \
        curl zip unzip tar xorg-dev libglu1-mesa-dev libxcursor-dev \
        libxml2-dev libxinerama-dev libcurl4-openssl-dev gettext nasm \
        gcc g++ git make bison ninja-build \
        && apt clean

# Meson
RUN python3 -m pip install meson

# cmake
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.26.3/cmake-3.26.3-linux-aarch64.tar.gz | tar -xzf - --strip-components=1 -C /usr/

# vcpkg
RUN git clone --depth 1 https://github.com/simon987/vcpkg.git && cd vcpkg
RUN cd /vcpkg/ && ./bootstrap-vcpkg.sh

RUN VCPKG_FORCE_SYSTEM_BINARIES=true ./vcpkg/vcpkg install \
        curl[core,openssl] sqlite3 cpp-jwt pcre cjson brotli libarchive[core,bzip2,libxml2,lz4,lzma,lzo] pthread tesseract libxml2 libmupdf gtest mongoose libraw gumbo ffmpeg[core,avcodec,avformat,swscale,swresample] \
        && rm -rf /root/.cache/vcpkg /vcpkg/downloads /vcpkg/buildtrees /vcpkg/downloads

COPY patches/* ./
RUN cd /vcpkg/ && patch -p1 < /fix-libraw.patch

