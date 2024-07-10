#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?' ERR

git clone https://github.com/ctu-mrs/mrs_docker
cd mrs_docker/recipes

docker login --username klaxalk --password $TOKEN

# docker build . --file docker/without_linux_setup --tag ctumrs/mrs_uav_system:latest

WEEK_TAG="`date +%Y`_w`date +%V`"

docker buildx create --name container --driver=docker-container
docker buildx build . --file Dockerfile --builder container --tag ctumrs/mrs_uav_system:latest --tag ctumrs/mrs_uav_system:${WEEK_TAG} --platform=linux/amd64,linux/arm64,linux/arm/v7 --push 
