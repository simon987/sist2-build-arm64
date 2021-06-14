FROM ubuntu:20.04

MAINTAINER simon987 <me@simon987.net>

RUN apt update

RUN DEBIAN_FRONTEND="noninteractive" apt install -y pkg-config python3 python3-pip \
	yasm ragel automake autotools-dev wget libtool libssl-dev \
        curl zip unzip tar xorg-dev libglu1-mesa-dev libxcursor-dev \
        libxml2-dev libxinerama-dev libcurl4-openssl-dev gettext \
        gcc g++ git make \
        && apt clean

# cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.20.2/cmake-3.20.2.tar.gz && \
    tar -xzf cmake-*.tar.gz && cd cmake-* && ./bootstrap && make -j4 && make install && rm -rf /cmake-*

# Ninja
RUN git clone git://github.com/ninja-build/ninja.git && \
	cd ninja && git checkout release && \
	cmake -Bbuild-cmake -H. && cmake --build build-cmake && \
	mv build-cmake/ninja /usr/bin/ && rm -rf /ninja/

# Meson
RUN python3 -m pip install meson

# vcpkg
RUN git clone --depth 1 https://github.com/microsoft/vcpkg.git
RUN cd vcpkg && ./bootstrap-vcpkg.sh

ADD patches/* /
RUN patch -p0 < mupdf-curl-dep.patch
RUN patch -p0 < mongoose-master.patch
RUN patch -p0 < glib-meson-fix.patch

RUN VCPKG_FORCE_SYSTEM_BINARIES=true ./vcpkg/vcpkg install \
        curl[core,openssl] \
        && rm -rf /root/.cache/vcpkg /vcpkg/downloads /vcpkg/buildtrees /vcpkg/downloads

RUN  mkdir /vcpkg/downloads; VCPKG_FORCE_SYSTEM_BINARIES=true ./vcpkg/vcpkg install \
      lmdb cjson glib brotli libarchive[core,bzip2,libxml2,lz4,lzma,lzo] pthread tesseract libxml2 libmupdf gtest mongoose libuuid libmagic libraw jasper lcms gumbo \
       && rm -rf /root/.cache/vcpkg /vcpkg/downloads /vcpkg/buildtrees /vcpkg/downloads
