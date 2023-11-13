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

                stable_ref = ""
                unstable_ref = ""

                try:
                    stable_ref = properties['stable_ref']
                except:
                    pass

                try:
                    unstable_ref = properties['unstable_ref']
                except:
                    pass

                print("{} {} {} {}".format(package, url, stable_ref, unstable_ref))

if __name__ == '__main__':
    main()
