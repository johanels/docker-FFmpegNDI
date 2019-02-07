# BETA: Docker FFMPEG with NDI support

Because of the NewTek NDI® SDK license agreement, we cannot distribute the SDK into a Docker image directly. Here I've tried to make compiling it in as simple as possible.

Unfortunately we are using the Linux SDK so you will have to build the Docker image on Linux or MacOS.

Start by cloning this repository and go into it.

```bash
git clone https://github.com/johanels/docker-FFMPEG.git
cd docker-FFMPEG
```

Now register and request the NewTek NDI® Software Developer Kit download link from https://www.newtek.com/ndi/sdk/#download-sdk into the repository folder. Make executable and run the file.

```bash
chmod 755 NDISDKLINUX
./NDISDKLINUX
```

Read and accept the license agreement. You should now have a new folder in the repository directory called "NDI SDK for Linux". You can now build the Docker image and in the Dockerfile it should copy the NDI SDK files into the image as part of the build.

```bash
docker build . -t ffmpegndi
```

```bash
docker run -it --expose 49152-65535 -p 5353:5353 ffmpegndi -f libndi_newtek -find_sources 1 -i dummy
```

CURRENT DEBUG:
```bash
docker run -it -p 5353:5353 --network bridge --entrypoint='bash' ffmpegndi
LD_LIBRARY_PATH=/usr/local/lib ffmpeg -f libndi_newtek -find_sources 1 -i dummy
```

Credits:
* FFmpeg - https://www.ffmpeg.org
* NewTek NDI® SDK - https://www.newtek.com/ndi/sdk/
* NewTek NDI® port information - https://support.newtek.com/hc/en-us/articles/218109497-NDI-Video-Data-Flow
* docker - https://www.docker.com
* jrottenberg - https://hub.docker.com/r/jrottenberg/ffmpeg
