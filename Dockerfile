# ffmpeg - http://ffmpeg.org/download.html

FROM debian:stretch-slim AS base

RUN apt-get update && apt-get upgrade

# Add avahi for NDI discovery
RUN apt-get install -y avahi-daemon avahi-utils
ADD configs/avahi-daemon.conf /etc/avahi/avahi-daemon.conf

# Add some other dependencies
RUN apt-get install -y apt-utils libssl1.1 libglib2.0-0 libgomp1

# Create a Build Docker image
FROM base AS build

WORKDIR /tmp/workdir

RUN apt-get install -y libgcc-6-dev libstdc++ ca-certificates libcrypto++-dev expat git

ARG PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
ARG LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG PREFIX=/opt/ffmpeg
ARG MAKEFLAGS="-j2"

ENV FFMPEG_VERSION=4.1                \
    FDKAAC_VERSION=0.1.5              \
    X264_VERSION=20170226-2245-stable \
    X265_VERSION=2.3                  \
    SRC=/usr/local

RUN apt-get install -y autoconf \
      automake \
      bash \
      binutils \
      bzip2 \
      cmake \
      curl \
      coreutils \
      diffutils \
      file \
      g++ \
      gcc \
      gperf \
      libexpat-dev \
      libglib2.0-dev \
      libssl-dev \
      libtool \
      make \
      python \
      tar \
      yasm \
      zlib1g-dev

## NewTek NDI Software Developer Kit 3.8 https://www.newtek.com/ndi/sdk/#download-sdk
# ADD ["NDI SDK for Linux/lib/x86_64-linux-gnu/*", "/usr/lib/"]
ADD ["NDI SDK for Linux", "/usr/local/ndi/"]

## x264 http://www.videolan.org/developers/x264.html
RUN DIR=/tmp/x264 && \
    mkdir -p ${DIR} && \
    cd ${DIR} && \
    curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
    tar -jx --strip-components=1 && \
    ./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli && \
    make && \
    make install && \
    rm -rf ${DIR}

### x265 http://x265.org/
RUN DIR=/tmp/x265 && \
    mkdir -p ${DIR} && \
    cd ${DIR} && \
    curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
    tar -zx && \
    cd x265_${X265_VERSION}/build/linux && \
    sed -i "/-DEXTRA_LIB/ s/$/ -DCMAKE_INSTALL_PREFIX=\${PREFIX}/" multilib.sh && \
    sed -i "/^cmake/ s/$/ -DENABLE_CLI=OFF/" multilib.sh && \
    ./multilib.sh && \
    make -C 8bit install && \
    rm -rf ${DIR}

### fdk-aac https://github.com/mstorsjo/fdk-aac
RUN DIR=/tmp/fdk-aac && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}

## ffmpeg https://ffmpeg.org/
RUN  DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2

RUN DIR=/tmp/ffmpeg && cd ${DIR} && \
        ./configure \
        --enable-gpl \
        --enable-libndi_newtek \
        --enable-libx264 \
        --enable-nonfree \
        --extra-cflags="-I${PREFIX}/include -I/usr/local/ndi/include" \
        --extra-ldflags="-L${PREFIX}/lib -L/usr/local/ndi/lib/x86_64-linux-gnu" \
        --prefix="${PREFIX}" && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${PREFIX}/bin

RUN ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
    cp ${PREFIX}/bin/* /usr/local/bin/ && \
    cp /usr/local/ndi/lib/x86_64-linux-gnu/* /usr/local/lib/ && \
    cp -r ${PREFIX}/share/ffmpeg /usr/local/share/ && \
    LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf

### Release Stage
FROM        base AS release
MAINTAINER  Johan Els <johan@who-els.co.za>

EXPOSE 5353/UDP
EXPOSE 5960-5969

ENV LD_LIBRARY_PATH /usr/local/lib
CMD ["--help"]
ADD ["scripts/entrypoint.sh", "/usr/local/bin/"]
ENTRYPOINT  ["entrypoint.sh"]

COPY --from=build /usr/local /usr/local
