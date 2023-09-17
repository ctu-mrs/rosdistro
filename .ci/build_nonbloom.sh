#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

LIST=$1
VARIANT=$2
PACKAGE_NAME=$3
WORK_DIR=/tmp/repo
ARTIFACTS_FOLDER=/tmp/artifacts
IDX_FILE=$ARTIFACTS_FOLDER/idx.txt

YAML_FILE=${LIST}.yaml

sudo apt-get -y install dpkg-dev

ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

# we already have a docker image with ros for the ARM build
if [[ "$ARCH" != "arm64" ]]; then
  curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ros_ppa.sh | bash
fi

curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ppa.sh | bash

REPO=$(./.ci/get_repo_source.py $YAML_FILE $VARIANT $ARCH $PACKAGE_NAME)

mkdir -p $WORK_DIR

cd $WORK_DIR

PACKAGE=$(echo "$REPO" | awk '{print $1}')
URL=$(echo "$REPO" | awk '{print $2}')
BRANCH=$(echo "$REPO" | awk '{print $3}')

echo "$0: cloning '$URL --depth 1 --branch $BRANCH' into '$PACKAGE'"
git clone $URL --recurse-submodules --shallow-submodules --depth 1 --branch $BRANCH $PACKAGE

cd $WORK_DIR/$PACKAGE/

./.ci/build_package.sh $ARTIFACTS_FOLDER
