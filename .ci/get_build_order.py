#!/bin/python3

import os
import xml.etree.ElementTree as ET
from collections import defaultdict, deque
import copy

def find_packages(root_dir):
    packages = {}

    for subdir, _, files in os.walk(root_dir):
        if "package.xml" in files:
            if "CATKIN_IGNORE" in files:
                continue

            package_path = os.path.join(subdir, "package.xml")
            tree = ET.parse(package_path)
            root = tree.getroot()

            name_elem = root.find("name")
            if name_elem is None:
                continue

            package_name = name_elem.text.strip()

            dependencies = [dep.text.strip() for dep in root.findall("depend") if dep.text]

            packages[package_name] = {
                "path": subdir,
                "dependencies": dependencies
            }

    return packages

def topological_sort(packages):

    graph = defaultdict(set) # who depends on each package
    indegree = defaultdict(int)
    all_packages = set(packages.keys())

    # Build dependency graph
    for pkg, info in packages.items():
        for dep in info["dependencies"]:
            if dep in all_packages:
                graph[dep].add(pkg)
                indegree[pkg] += 1

    # Initialize queue with packages having no dependencies
    queue = deque([pkg for pkg in all_packages if indegree[pkg] == 0 and graph[pkg]])

    for package in [pkg for pkg in all_packages if indegree[pkg] == 0 and not graph[pkg]]:
        queue.append(package)

    build_order = []

    while queue:
        pkg = queue.popleft()
        build_order.append(pkg)

        for dependent in graph[pkg]:
            indegree[dependent] -= 1
            if indegree[dependent] == 0:
                queue.append(dependent)

    for idx_large in range(0, len(build_order)-2):
        for idx_small in range(0, len(build_order)-idx_large-1):

            idx_left = idx_small
            idx_right = idx_small+1

            if build_order[idx_right] not in graph[build_order[idx_left]]:

                left = copy.deepcopy(build_order[idx_left])
                right = copy.deepcopy(build_order[idx_right])
                build_order[idx_left] = right
                build_order[idx_right] = left

    # If all dependencies were not resolved, there's a cyclic dependency
    if len(build_order) != len(all_packages):
        raise ValueError("Cyclic dependency detected in the package dependencies.")

    return build_order

def main(root_dir):
    packages = find_packages(root_dir)
    try:
        build_order = topological_sort(packages)
        for pkg in build_order:
            print(pkg)
    except ValueError as e:
        print("Error:", e)

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python build_order.py <root_directory>")
    else:
        main(sys.argv[1])
