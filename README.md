# BETA: Docker FFMPEG with NDI support

Because of the NewTek NDI® SDK license agreement, we cannot distribute the SDK into a Docker image directly. Here I've tried to make compiling it as simple as possible and then use this version to build a point2point NDI link over the Internet. The theory is that if you can get NDI into and out of FFmpeg, FFmpeg has a documented point2point streaming documented on their site.

The challenge is that NewTek NDI® uses Bonjour to announce the available streams and using Docker, you might not be on the same Bonjour network.

For now I will be using the Linux and MacOS NewTek NDI® SDK so you will have to build the Docker image on Linux or MacOS.

Start by cloning this repository and go into it.

```bash
git clone https://github.com/johanels/docker-FFMPEG.git
cd docker-FFMPEG
```

Now register and request the NewTek NDI® Software Developer Kit download link from https://www.newtek.com/ndi/sdk/#download-sdk and then download the Linux version into the repository folder.

For the linux one, make executable and run the file:

```bash
chmod 755 NDISDKLINUX
./NDISDKLINUX
```
Read and accept the license agreement. You should now have a new folder in the repository directory called "NDI SDK for Linux".


## Docker
You can now build the Docker image and in the Dockerfile it should copy the NDI SDK files into the image as part of the build.

### Building

```bash
docker build . -t ffmpegndi
```

### Debug:
```bash
docker run -it --rm --name ffmpegndi --network host --expose 5353 --expose 5353/udp --expose 49152-65535 -v ~/Downloads/:/temp/ --entrypoint='bash' ffmpegndi
```

## MacOS
Compiling FFMPEG with NewTek NDI® on MacOS is also a challenge, but here is what I have. Download NewTek NDI® for MacOS and install it. It dumps itself in the root of the drive, which I'm not happy about, but what can we do?

### Building

```bash
brew install automake fdk-aac git lame libass libtool libvorbis libvpx opus sdl shtool texi2html theora wget x264 x265 xvid nasm

git clone http://source.ffmpeg.org/git/ffmpeg.git ffmpeg

cd ffmpeg

ln -s /NewTek\ NDI\ SDK/ ndi
sudo ln -s /usr/local/lib/libndi.3.dylib /usr/local/lib/libndi.dylib

./configure  --prefix=/usr/local \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libndi_newtek \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libxvid \
  --enable-nonfree \
  --extra-cflags="-I$HOME/Development/ffmpeg/ndi/include" \
  --extra-ldflags="-L$HOME/Development/ffmpeg/ndi/lib/i686" \
  --extra-libs="-lpthread -lm" \
  --samples=fate-suite/

./configure --enable-nonfree \
  --enable-gpl \
  --enable-libndi_newtek \
  --enable-libx264 \
  --enable-nonfree \
  --extra-cflags="-I$HOME/Development/ffmpeg/ndi/include" \
  --extra-ldflags="-L$HOME/Development/ffmpeg/ndi/lib/i686"

make
```

## FFmpeg Commands

### List available NDI® sources:

```bash
ffmpeg -f libndi_newtek -extra_ips "10.10.10.100" -find_sources 1 -i dummy
docker run -it --rm ffmpegndi -f libndi_newtek -extra_ips "10.10.10.100" -find_sources 1 -i dummy
```

### Stream file to NDI output:
```bash
ffmpeg -re -i /temp/input.mp4 -f libndi_newtek -pix_fmt uyvy422 OUTPUT
docker run -it --rm --network host --expose 5353 --expose 49152-65535 -v $PWD/:/temp/ ffmpegndi -re -i /temp/input.mp4 -f libndi_newtek -pix_fmt uyvy422 OUTPUT
```

### Point-to-Point Stream:
```bash
docker run -it --name input --rm --network host --expose 5353 --expose 49152-65535 ffmpegndi -f libndi_newtek -extra_ips 10.10.10.100 -i "OUTPUT.LOCAL (Scan Converter)" -f mpegts udp://10.10.10.101:1234

docker run -it --name output --rm --network host --expose 5353 --expose 49152-65535 ffmpegndi -i udp://@:1234 -f libndi_newtek -pix_fmt uyvy422 OUTPUT
```

### Monitor NDI source:
```bash
ffplay -f libndi_newtek -i "Sample"
```

## References:
* FFmpeg - https://www.ffmpeg.org
** Streaming Guide - https://trac.ffmpeg.org/wiki/StreamingGuide
** MacOS Compiling yourself -  https://trac.ffmpeg.org/wiki/CompilationGuide/macOS#CompilingFFmpegyourself
* NewTek NDI® SDK - https://www.newtek.com/ndi/sdk/
* NewTek NDI® port information - https://support.newtek.com/hc/en-us/articles/218109497-NDI-Video-Data-Flow
* docker - https://www.docker.com
* jrottenberg - https://hub.docker.com/r/jrottenberg/ffmpeg
* Raspberry Pi
** Build FFmpeg and mpv – Automatically in 54 Minutes! - https://www.raspberrypi.org/forums/viewtopic.php?t=199775
