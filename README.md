# BETA: Docker FFMPEG with NDI support

Because of the NewTek NDI® SDK license agreement, we cannot distribute the SDK into a Docker image directly. Here I've tried to make compiling it in as simple as possible and then use this version to build a point2point NDI link over the Internet. The theory is that if you can get NDI into and out of FFmpeg, FFmpeg has a documented point2point streaming as documented on their site.

The challenge is that NewTek NDI® uses Bonjour to announce the available streams and using Docker, you might not be on the same Bonjour networks.

For now I will be using the Linux and MacOS NewTek NDI® SDK so you will have to build the Docker image on Linux or MacOS.

Start by cloning this repository and go into it.

```bash
git clone https://github.com/johanels/docker-FFMPEG.git
cd docker-FFMPEG
```

Now register and request the NewTek NDI® Software Developer Kit download link from https://www.newtek.com/ndi/sdk/#download-sdk and then download the into the repository folder.

For the linux one, make executable and run the file.

```bash
chmod 755 NDISDKLINUX
./NDISDKLINUX
```

Read and accept the license agreement. You should now have a new folder in the repository directory called "NDI SDK for Linux". You can now build the Docker image and in the Dockerfile it should copy the NDI SDK files into the image as part of the build.

```bash
docker build . -t ffmpegndi
```

List available NDI® sources:
```bash
docker run -it --rm --network host --expose 5353 --expose 49152-65535 ffmpegndi -f libndi_newtek -extra_ips "10.1.1.107" -find_sources 1 -i dummy
```

Stream file to NDI output:
```bash
docker run -it --rm --network host --expose 5353 --expose 49152-65535 -v ~/Downloads/:/temp/ ffmpegndi -i /temp/input.mp4 -f libndi_newtek -pix_fmt uyvy422 Sample
```

Monitor NDI source:
```bash
ffplay -f libndi_newtek -i "Sample"
```

Point-to-Point Stream:
```bash
docker run -it --rm --network host --expose 5353 --expose 49152-65535 ffmpegndi -f libndi_newtek -i "Scan\ Converter" -extra_ips 10.1.1.107 -f mpegts udp://10.1.1.101:1234

docker run -it --rm --network host --expose 5353 --expose 49152-65535 ffmpegndi -i udp://@:1234 -f libndi_newtek -pix_fmt uyvy422 "Output"
```

Tests:
```bash
ffmpeg -f libndi_newtek -i "JOHANELS-MACBOOK-15.LOCAL (Scan Converter)" -f mpegts udp://10.1.1.101:1234
```

Debug:
```bash
docker run -it --rm --network bridge --expose 5353 --expose 5353/udp --expose 49152-65535 -v ~/Downloads/:/temp/ --entrypoint='bash' ffmpegndi
  avahi-daemon -D
  ffmpeg -i /temp/input.mp4 -f libndi_newtek -pix_fmt uyvy422 Sample
```

References:
* FFmpeg - https://www.ffmpeg.org
** Streaming Guide - https://trac.ffmpeg.org/wiki/StreamingGuide
* NewTek NDI® SDK - https://www.newtek.com/ndi/sdk/
* NewTek NDI® port information - https://support.newtek.com/hc/en-us/articles/218109497-NDI-Video-Data-Flow
* docker - https://www.docker.com
* jrottenberg - https://hub.docker.com/r/jrottenberg/ffmpeg


Compiling FFMPEG with NewTek NDI® on MacOS:
* https://trac.ffmpeg.org/wiki/CompilationGuide/macOS#CompilingFFmpegyourself
```bash
git clone http://source.ffmpeg.org/git/ffmpeg.git ffmpeg
cd ffmpeg
./configure  --prefix=/usr/local --enable-gpl --enable-nonfree --enable-libass \
--enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libtheora \
--enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 \
--enable-libopus --enable-libxvid \
--enable-libndi_newtek \
--extra-cflags="-I../ndi-sdk/include" \
--extra-ldflags="-Ln../di-sdk/lib/x64" \
--samples=fate-suite/
make
```
