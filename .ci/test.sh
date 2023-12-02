#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

LIST=mrs
REPOSITORY_NAME=$1
ARTIFACT_FOLDER=$2
VARIANT=$3
WORKSPACE=/tmp/workspace

YAML_FILE=${LIST}.yaml

# needed for building open_vins
export ROS_VERSION=1

sudo apt-get -y install dpkg-dev

ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

# we already have a docker image with ros for the ARM build
if [[ "$ARCH" != "arm64" ]]; then
  curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ros_ppa.sh | bash
fi

curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ppa.sh | bash

sudo apt-get -y -q install ros-noetic-desktop
sudo apt-get -y -q install ros-noetic-mrs-uav-system
sudo apt-get -y -q install lcov

THIS_TEST_REPOS=$(./.ci/get_repo_source.py $YAML_FILE $VARIANT $ARCH $REPOSITORY_NAME)

echo "$0: unpack the workspace"

mv $ARTIFACT_FOLDER/workspace.tar.gz /tmp
cd /tmp
tar -xvzf workspace.tar.gz

## | ---------------- clone the tested package ---------------- |

cd $WORKSPACE/src

echo "$0: cloning the package"

# clone and checkout
echo "$THIS_TEST_REPOS" | while IFS= read -r REPO; do

  PACKAGE=$(echo "$REPO" | awk '{print $1}')
  URL=$(echo "$REPO" | awk '{print $2}')
  BRANCH=$(echo "$REPO" | awk '{print $3}')

  [ ! -e ${PACKAGE} ] && echo "$0: cloning '$URL --depth 1 --branch $BRANCH' into '$PACKAGE'"
  [ ! -e ${PACKAGE} ] && git clone $URL --recurse-submodules --shallow-submodules --depth 1 --branch $BRANCH $PACKAGE

done

source $WORKSPACE/devel/setup.bash

echo "$0: installing rosdep dependencies"

rosdep install --from-path .

echo "$0: building the workspace"

catkin build --limit-status-rate 0.2
catkin build --limit-status-rate 0.2 --catkin-make-args tests

echo "$0: testing"

cd $WORKSPACE/src/$REPOSITORY_NAME
ROS_DIRS=$(find . -name package.xml -printf "%h\n")

for DIR in $ROS_DIRS; do
  cd $WORKSPACE/src/$REPOSITORY_NAME/$DIR
  catkin test --this -i
done

echo "$0: tests finished"

echo "$0: storing coverage data"

lcov --capture --directory ${WORKSPACE} --output-file /tmp/coverage.original
lcov --remove /tmp/coverage.original "*/test/*" --output-file /tmp/coverage.removed || echo "$0: coverage tracefile is empty"
lcov --extract /tmp/coverage.removed "$WORKSPACE/src/*" --output-file $ARTIFACT_FOLDER/$REPOSITORY_NAME.info || echo "$0: coverage tracefile is empty"
