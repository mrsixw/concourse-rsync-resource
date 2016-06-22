FROM alpine:edge
MAINTAINER Steve Williams <mrsixw@gmail.com>

RUN apk update && apk upgrade && \
    apk add --update  curl wget bash tree python rsync

COPY ./assets/check /opt/resource/check
COPY ./assets/in /opt/resource/in
COPY ./assets/out /opt/resource/out
RUN mkdir -p /mnt/concourse_share && chmod 777 /mnt/concourse_share
