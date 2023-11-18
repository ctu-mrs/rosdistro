#!/usr/bin/python3

import yaml
import sys

def main():

    if len(sys.argv) == 3:
        file_path = sys.argv[1]
        build_for = sys.argv[2]
    else:
        return

    with open(file_path, "r") as file:

        try:
            data = yaml.safe_load(file)
        except yaml.YAMLError as exc:
            print(exc)

        for package in data:

            properties = data[package]

            architecture = properties['architecture']

            url = properties['source']

            if build_for in architecture:

                stable_ref = "none"
                testing_ref = "none"
                unstable_ref = "none"
                ros_test = 0

                refs = properties['git_refs']

                try:
                    stable_ref = refs['stable']
                except:
                    pass

                try:
                    testing_ref = refs['testing']
                except:
                    pass

                try:
                    unstable_ref = refs['unstable']
                except:
                    pass

                try:
                    ros_test = bool(properties['ros_test'])
                except:
                    pass

                print("{} {} {} {} {} {}".format(package, url, stable_ref, testing_ref, unstable_ref, ros_test))

if __name__ == '__main__':
    main()
