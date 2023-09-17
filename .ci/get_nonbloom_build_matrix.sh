#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?, log:" && cat /tmp/log.txt' ERR

DEBUG=false

LIST=$1
VARIANT=$2
ARCH=$3

YAML_FILE=$LIST.yaml

./.ci_scripts/package_build/add_ros_ppa.sh >> /tmp/log.txt 2>&1

REPOS=$(./.ci/parse_yaml.py $YAML_FILE $VARIANT $ARCH)

# RESULT='{"matrix": ['
RESULT='['

FIRST=true

# clone and checkout
echo "$REPOS" | while IFS= read -r REPO; do

  PACKAGE=$(echo "$REPO" | awk '{print $1}')

  if $FIRST; then
    RESULT=$RESULT\"$PACKAGE\"
    FIRST=false
  else
    RESULT="$RESULT, \"$PACKAGE\""
  fi

done

# RESULT="$RESULT]}"
RESULT="$RESULT]"

echo $RESULT

$DEBUG && echo "Done cloning"
