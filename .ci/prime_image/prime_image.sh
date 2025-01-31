#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

cd $MY_PATH

docker pull ctumrs/ros:noetic

docker buildx use default

docker build . --file Dockerfile --tag ctumrs/ros:noetic_builder --progress plain

docker save ctumrs/ros:noetic_builder | gzip > /tmp/artifacts/builder.tar.gz
