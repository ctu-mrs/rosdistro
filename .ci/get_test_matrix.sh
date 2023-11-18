#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?' ERR

DEBUG=false

LIST=mrs
ARCH=amd64

YAML_FILE=$LIST.yaml

REPOS=$(./.ci/parse_yaml.py $YAML_FILE $ARCH)

FIRST=true

echo -n "["

echo "$REPOS" | while IFS= read -r REPO; do

  $DEBUG && echo "Cloning $REPO"

  PACKAGE=$(echo "$REPO" | awk '{print $1}')
  URL=$(echo "$REPO" | awk '{print $2}')
  TEST=$(echo "$REPO" | awk '{print $6}')

  if [[ "$TEST" != "True" ]]; then
    continue
  fi

  if $FIRST; then
    echo -n "\"$PACKAGE\""
    FIRST=false
  else
    echo -n ", \"$PACKAGE\""
  fi

done

echo "]"
