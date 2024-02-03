#!/bin/bash

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

LIST=$1
VARIANT=$2
PACKAGE_NAME=$3
WORK_DIR=/tmp/repo
ARTIFACTS_FOLDER=/tmp/artifacts

YAML_FILE=${LIST}.yaml

sudo apt-get -y install dpkg-dev

sudo pip3 install -U gitman

ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

REPO=$(./.ci/get_repo_source.py $YAML_FILE $VARIANT $ARCH $PACKAGE_NAME)

mkdir -p $WORK_DIR

cd $WORK_DIR

PACKAGE=$(echo "$REPO" | awk '{print $1}')
URL=$(echo "$REPO" | awk '{print $2}')
BRANCH=$(echo "$REPO" | awk '{print $3}')

echo "$0: cloning '$URL --depth 1 --branch $BRANCH' into '$PACKAGE'"
git clone $URL --recurse-submodules --branch $BRANCH $PACKAGE

cd $WORK_DIR/$PACKAGE/

[[ -e .gitman.yml || -e .gitman.yaml ]] && gitman install

cp -r $MY_PATH/../.ci_scripts ./

# call the build script within the clone repository
./.ci/build_package.sh $VARIANT $ARTIFACTS_FOLDER
