#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

ARTIFACT_FOLDER=$1

sudo apt-get -y -q install lcov

# are there any coverage files?

ARGS=""

for file in `ls $ARTIFACT_FOLDER | grep ".info"`; do

  ARGS="-a ${ARTIFACT_FOLDER}/${file}"

done

lcov $ARGS --output-file /tmp/coverage.info

genhtml -o /tmp/coverage_html /tmp/coverage.info | tee /tmp/coverage.log

COVERAGE_PCT=`cat /tmp/coverage.log | tail -n 1 | awk '{print $2}'`

echo "Coverage: $COVERAGE_PCT"
