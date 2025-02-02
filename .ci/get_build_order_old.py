#!/usr/bin/python3

import sys
from catkin_pkg.topological_order import topological_order

def main():

    if len(sys.argv) == 2:
        ws_path = sys.argv[1]
    else:
        return ""

    order = topological_order(ws_path)

    for touple in order:
        print("{}".format(touple[0]))

if __name__ == '__main__':
    main()
