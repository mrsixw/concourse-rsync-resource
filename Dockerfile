FROM alpine:edge
MAINTAINER Steve Williams <mrsixw@gmail.com>

RUN apk update && apk upgrade && \
    apk add --update  bash rsync jq openssh

COPY ./assets/* /opt/resource/
