#!/bin/sh

/usr/sbin/avahi-daemon -D

/usr/local/bin/ffmpeg $@
