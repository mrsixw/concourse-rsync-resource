FROM alpine:edge
MAINTAINER Steve Williams <mrsixw@gmail.com>

RUN apk update && apk upgrade && \
    apk add --update  curl wget bash tree python rsync jq nfs-utils openssh

COPY ./assets/* /opt/resource/
