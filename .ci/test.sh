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

sudo pip3 install -U gitman

THIS_TEST_REPOS=$(./.ci/get_repo_source.py $YAML_FILE $VARIANT $ARCH $REPOSITORY_NAME)

echo "$0: unpack the workspace"

# if the workspace is passed down from previous jobs
if [ -e $ARTIFACT_FOLDER/workspace.tar.gz ]; then

  mv $ARTIFACT_FOLDER/workspace.tar.gz /tmp
  cd /tmp
  tar -xvzf workspace.tar.gz

else

  mkdir -p $WORKSPACE/src

  cd $WORKSPACE

  source /opt/ros/noetic/setup.bash
  catkin init

  catkin config --profile debug --cmake-args -DCMAKE_BUILD_TYPE=Debug
  catkin profile set debug

  catkin build

fi

## | ---------------- clone the tested package ---------------- |

echo "$0: cloning the package"

# clone and checkout
echo "$THIS_TEST_REPOS" | while IFS= read -r REPO; do

  cd $WORKSPACE/src

  PACKAGE=$(echo "$REPO" | awk '{print $1}')
  URL=$(echo "$REPO" | awk '{print $2}')
  BRANCH=$(echo "$REPO" | awk '{print $3}')

  [ ! -e ${PACKAGE} ] && echo "$0: cloning '$URL --depth 1 --branch $BRANCH' into '$PACKAGE'" || echo "$0: not cloning, already there"
  [ ! -e ${PACKAGE} ] && git clone $URL --recurse-submodules --shallow-submodules --depth 1 --branch $BRANCH $PACKAGE || echo "$0: not cloning, already there"

  cd $PACKAGE
  [[ -e .gitman.yml || -e .gitman.yaml ]] && gitman install || echo "no gitman modules to install"

done

cd $WORKSPACE/src

source $WORKSPACE/devel/setup.bash

echo "$0: installing rosdep dependencies"

rosdep install -y --from-path .

echo "$0: building the workspace"

catkin build --limit-status-rate 0.2 --cmake-args -DCOVERAGE=true -DMRS_ENABLE_TESTING=true
catkin build --limit-status-rate 0.2 --cmake-args -DCOVERAGE=true -DMRS_ENABLE_TESTING=true --catkin-make-args tests

echo "$0: testing"

## set coredump generation

mkdir -p /tmp/coredump
sudo sysctl -w kernel.core_pattern="/tmp/coredump/%e_%p.core"
ulimit -c unlimited

cd $WORKSPACE/src/$REPOSITORY_NAME
ROS_DIRS=$(find . -name package.xml -printf "%h\n")

for DIR in $ROS_DIRS; do
  cd $WORKSPACE/src/$REPOSITORY_NAME/$DIR
  FAILED=0
  catkin test --limit-status-rate 0.2 --this -p 1 -s || FAILED=1
done

echo "$0: tests finished"

if ! [[ "$FAILED" -eq 0 ]]; then

  echo "$0: storing coverage data"

  lcov --capture --directory ${WORKSPACE} --output-file /tmp/coverage.original
  lcov --remove /tmp/coverage.original "*/test/*" --output-file /tmp/coverage.removed || echo "$0: coverage tracefile is empty"
  lcov --extract /tmp/coverage.removed "$WORKSPACE/src/*" --output-file $ARTIFACT_FOLDER/$REPOSITORY_NAME.info || echo "$0: coverage tracefile is empty"

fi

ls /tmp/coredump

if [ -z "$(ls -A /tmp/coredump)" ]; then
  exit $FAILED
else
  echo "$0: core dumps detected"
fi

cd /tmp
git clone https://$PUSH_TOKEN@github.com/ctu-mrs/buildfarm_coredumps
cd /tmp/buildfarm_coredumps

git config user.email github@github.com
git config user.name github

d="$(date +"%Y-%m-%d_%H.%M.%S")_$REPOSITORY_NAME"
mkdir -p "$d"
cd "$d"
mv /tmp/coredump/* ./
cp -L $WORKSPACE/devel/lib/*.so ./
cd ..
tar -cvzf "$d.tar.gz" "$d"
rm -rf "$d"

git add -A
git commit -m "Added new coredumps"

# the upstream might have changed in the meantime, try to merge it first
git fetch
git merge origin/master

git push

echo "$0: core dumps pushed"

exit 1
