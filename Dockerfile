FROM --platform="linux/arm64/v8" ubuntu:20.04

MAINTAINER simon987 <me@simon987.net>

RUN apt update

RUN DEBIAN_FRONTEND="noninteractive" apt install -y pkg-config python3 python3-pip \
	yasm ragel automake autotools-dev wget libtool libssl-dev \
        curl zip unzip tar xorg-dev libglu1-mesa-dev libxcursor-dev \
        libxml2-dev libxinerama-dev libcurl4-openssl-dev gettext \
        gcc g++ git make bison \
        && apt clean

# cmake
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-aarch64.tar.gz | tar -xzf - --strip-components=1 -C /usr/

# Ninja
RUN git clone git://github.com/ninja-build/ninja.git && \
	cd ninja && git checkout release && \
	cmake -Bbuild-cmake -H. && cmake --build build-cmake && \
	mv build-cmake/ninja /usr/bin/ && rm -rf /ninja/

# Meson
RUN python3 -m pip install meson

# vcpkg
RUN git clone https://github.com/microsoft/vcpkg.git && cd vcpkg && git checkout 16c865ef9805b886ebae97964d45b3b52598aab7 
RUN cd vcpkg && ./bootstrap-vcpkg.sh

ADD patches/* /
RUN cd /vcpkg; patch -p1 < ../mupdf-curl-dep.patch
RUN cd /vcpkg; patch -p1 < ../mongoose-master.patch
RUN cd /vcpkg; patch -p1 < ../libraw.patch

RUN VCPKG_FORCE_SYSTEM_BINARIES=true ./vcpkg/vcpkg install \
        curl[core,openssl] \
        && rm -rf /root/.cache/vcpkg /vcpkg/downloads /vcpkg/buildtrees /vcpkg/downloads

RUN  mkdir /vcpkg/downloads; VCPKG_FORCE_SYSTEM_BINARIES=true ./vcpkg/vcpkg install \
      lmdb cjson glib brotli libarchive[core,bzip2,libxml2,lz4,lzma,lzo] pthread tesseract libxml2 libmupdf gtest mongoose libuuid libmagic libraw jasper lcms gumbo \
       && rm -rf /root/.cache/vcpkg /vcpkg/downloads /vcpkg/buildtrees /vcpkg/downloads

RUN mkdir -p /debug/lib/ && mkdir -p /include && \
 cp -r /vcpkg/installed/arm64-linux/include/cjson/ /include/ && \
 cp /vcpkg/installed/arm64-linux/debug/lib/libcjson.a /debug/lib/ && \
 cp /vcpkg/installed/arm64-linux/lib/libcjson.a /lib/
