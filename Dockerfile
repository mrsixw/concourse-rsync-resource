FROM alpine:3.24
LABEL org.opencontainers.image.authors="Steve Williams <mrsixw@gmail.com>"

RUN apk add --no-cache bash rsync jq openssh-client-default

COPY ./assets/* /opt/resource/
