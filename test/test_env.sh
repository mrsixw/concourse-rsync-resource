#!/usr/bin/env bash

export SRC_DIR=$PWD
export BUILD_ID=1
export BUILD_NAME='my-build'
export BUILD_JOB_NAME='my-build-job'
export BUILD_PIPELINE_NAME='my-build-pipeline'
export ATC_EXTERNAL_URL='127.0.0.1/atc'

cat /opt/start/test.json | /opt/resource/check
