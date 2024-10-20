#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

cd $MY_PATH

docker login --username klaxalk --password $TOKEN

WEEK_TAG="`date +%Y`_w`date +%V`"

docker buildx create --name container --driver=docker-container --use

docker buildx build . --file Dockerfile --tag ctumrs/mrs_uav_system:latest --tag ctumrs/mrs_uav_system:${WEEK_TAG} --platform=linux/amd64,linux/arm64 --push 
