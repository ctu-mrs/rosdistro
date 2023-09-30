#!/usr/bin/python3

import yaml
import sys

def main():

    if len(sys.argv) == 4:
        file_path = sys.argv[1]
        variant = sys.argv[2]
        build_for = sys.argv[3]
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

                if variant == "stable":

                    try:
                        ref = properties['stable_ref']
                        print("{} {} {}".format(package, url, ref))
                    except:
                        pass

                else:

                    try:
                        ref = properties['unstable_ref']
                        print("{} {} {}".format(package, url, ref))
                    except:
                        pass

if __name__ == '__main__':
    main()
