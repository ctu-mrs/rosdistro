#!/bin/bash

VARIANT=stable
ARCH=amd64
LOCATION=~/git/mrs

LISTS=(
  'mrs'
  'nonbloom'
  'thirdparty'
)

for ((i=0; i < ${#LISTS[*]}; i++));
do

  LIST=${LISTS[$i]}

  YAML_FILE=../$LIST.yaml

  REPOS=$(../.ci/parse_yaml.py $YAML_FILE $VARIANT $ARCH)

  mkdir -p $LOCATION/$LIST


  echo "$REPOS" | while IFS= read -r REPO; do

    cd $LOCATION/$LIST

    echo "Cloning $REPO"

    PACKAGE=$(echo "$REPO" | awk '{print $1}')
    URL=$(echo "$REPO" | awk '{print $2}')
    BRANCH=$(echo "$REPO" | awk '{print $3}')

    if [ -e ./$PACKAGE ]; then

      echo "$0: repository '$URL' is already present, updating it"
      cd $PACKAGE
      git fetch
      git checkout $BRANCH
      git pull

    else

      echo "$0: cloning '$URL --branch $BRANCH' into '$PACKAGE'"
      git clone $URL --recurse-submodules --shallow-submodules --branch $BRANCH $PACKAGE

    fi

  done

done

echo "Done cloning"

echo $RESULT
