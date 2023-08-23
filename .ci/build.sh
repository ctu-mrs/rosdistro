#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

VARIANT=$1
PACKAGE_NAME=$2
WORKSPACE=/tmp/workspace
YAML_FILE=packages.yaml
ARTIFACTS_FOLDER=/tmp/artifacts

sudo apt-get -y install dpkg-dev

ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

# we already have a docker image with ros for the ARM build
if [[ "$ARCH" != "arm64" ]]; then
  curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ros_ppa.sh | bash
fi

curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ppa.sh | bash

# dependencies need for build the deb package
sudo apt-get -y install ros-noetic-catkin python3-catkin-tools
sudo apt-get -y install fakeroot debhelper
sudo pip3 install -U bloom

REPOS=$(./.ci/get_repo_source.py $YAML_FILE $VARIANT $ARCH $PACKAGE_NAME)

echo "$0: Installing deb packages from the provided artifacts folder"

sudo apt -y install $ARTIFACTS_FOLDER/*.deb || echo "no artifacts to install"

echo "$0: artifacts installed"

mkdir -p $WORKSPACE

cd $WORKSPACE
mkdir src
source /opt/ros/noetic/setup.bash
catkin init

cd src

# clone and checkout
echo "$REPOS" | while IFS= read -r REPO; do

  PACKAGE=$(echo "$REPO" | awk '{print $1}')
  URL=$(echo "$REPO" | awk '{print $2}')
  BRANCH=$(echo "$REPO" | awk '{print $3}')

  echo "$0: cloning '$URL --depth 1 --branch $BRANCH' into '$PACKAGE'"
  git clone $URL --recurse-submodules --shallow-submodules --depth 1 --branch $BRANCH $PACKAGE

  cd $WORKSPACE/src

done

BUILD_ORDER=$(catkin list -u)

echo ""
echo "$0: catking reported following topological build order:"
echo "$BUILD_ORDER"
echo ""

ROSDEP_FILE=$ARTIFACTS_FOLDER/generated_$ARCH.yaml

cat $ROSDEP_FILE

if [ -s $ROSDEP_FILE ]; then

  echo "$0: adding $ROSDEP_FILE to rodep"
  echo "$0: contents:"

  echo "yaml file://$ROSDEP_FILE" | sudo tee /etc/ros/rosdep/sources.list.d/temp.list

  rosdep update

fi

for PACKAGE in $BUILD_ORDER; do

  PKG_PATH=$(catkin locate $PACKAGE)

  echo "$0: cding to '$PKG_PATH'"
  cd $PKG_PATH

  rosdep install -y -v --rosdistro=noetic --from-paths ./

  export DEB_BUILD_OPTIONS="parallel=`nproc`"
  bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic

  SHA=$(git rev-parse --short HEAD)

  FUTURE_DEB_NAME=ros-noetic-$(echo $PACKAGE  | sed 's/_/-/g')

  HAS_TAG=$(apt-cache policy $FUTURE_DEB_NAME | grep Candidate | grep git_$SHA | wc -l)

  if [ -e $ARTIFACTS_FOLDER/compile_further.txt ] || [[ "$HAS_TAG" == "0" ]]; then

    echo "Github SHA $HAS_TAG not detecting, going to build it"

    epoch=1
    build_flag=$(date +%Y%m%d.%H%M%S)~git-$SHA

    sed -i "s/(/($epoch:/" ./debian/changelog
    sed -i "s/)/.${build_flag})/" ./debian/changelog

    fakeroot debian/rules "binary --parallel"

    DEB_NAME=$(dpkg --field ../*.deb | grep Package | awk '{print $2}')
    mv ../*.deb $ARTIFACTS_FOLDER

    echo "$PACKAGE:
    ubuntu: [$DEB_NAME]
  " >> $ROSDEP_FILE

    echo "1" >> $ARTIFACTS_FOLDER/compile_further.txt

  else

    echo "Github SHA $HAS_TAG detected, not going to build it"

    echo "$PACKAGE:
    ubuntu: [$FUTURE_DEB_NAME]
  " >> $ROSDEP_FILE

  fi

done

echo ""
echo "$0: the generated rosdep contains:"
echo ""
cat $ROSDEP_FILE
echo ""
