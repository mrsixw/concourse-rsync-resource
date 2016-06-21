FROM alpine:latest
MAINTAINER Steve Williams <mrsixw@gmail.com>

COPY check /opt/resource/check
COPY in /opt/resource/in
COPY out /opt/resource/out
RUN mkdir -p /mnt/concourse_share && chmod 777 /mnt/concourse_share
