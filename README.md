# MRS Buildfarm

This package defines the Github Workflows for build MRS debian packages.

## MRS ROS packages

MRS ROS packages are defined in [mrs.yaml](./mrs.yaml).

## Third-party ROS packages

Third-party ROS packages are defined in [thirdparty.yaml](./thirdparty.yaml).

## Non-ROS packages

Non-ROS (not build by bloom) packages are defined in [nonbloom.yaml](./nonbloom.yaml).

## Workflows

Github workflows are located in [.github/workflows](.github/workflows).

## CI Script

The workflows utilize common scripts from [ci_scripts](https://github.com/ctu-mrs/ci_scripts).
