#!/bin/python3

import os
import xml.etree.ElementTree as ET
from collections import defaultdict, deque
import copy
import re

def clean_xml(file_path):

    """ Reads an XML file, removes invalid comments, and returns a clean string. """
    with open(file_path, "r", encoding="utf-8") as f:
        xml_content = f.read()
    
    # Remove illegal comments (e.g., those containing "--" incorrectly)
    xml_content = re.sub(r'<!\s*--[^>]*--\s*>', '', xml_content, flags=re.DOTALL)
    
    return xml_content.strip()  # Ensure root remains on the first line

def find_packages(root_dir):

    packages = {}
    package_paths = {}
    
    for subdir, _, files in os.walk(root_dir):
        if "package.xml" in files:
            if "CATKIN_IGNORE" in files:
                continue
            package_path = os.path.join(subdir, "package.xml")

            xml_content = clean_xml(package_path)           

            root = ET.fromstring(xml_content)

            name_elem = root.find("name")
            if name_elem is None:
                continue

            package_name = name_elem.text.strip()
            
            dependencies = [dep.text.strip() for dep in root.findall("depend") if dep.text]
            dependencies = dependencies + [dep.text.strip() for dep in root.findall("build_depend") if dep.text]
            
            packages[package_name] = {
                "path": subdir,
                "dependencies": dependencies
            }

            package_paths[package_name] = subdir
    
    return packages, package_paths

def detect_cycle(graph, all_packages):
    visited = set()
    stack = set()
    cycle_packages = []
    
    def visit(pkg, path):
        if pkg in stack:  # Cycle detected
            cycle_packages.extend(path[path.index(pkg):] + [pkg])
            return True
        if pkg in visited:
            return False
        
        visited.add(pkg)
        stack.add(pkg)
        path.append(pkg)
        for neighbor in graph[pkg]:
            if visit(neighbor, path):
                return True
        stack.remove(pkg)
        path.pop()
        return False
    
    for pkg in all_packages:
        if pkg not in visited:
            if visit(pkg, []):
                return cycle_packages  # Return the cycle if found
    return None

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

    # Detect cycles before proceeding
    cycle = detect_cycle(graph, all_packages)
    if cycle:
        raise ValueError(f"Cyclic dependency detected: {' -> '.join(cycle)}")
    
    # Initialize queue with packages having no dependencies
    queue = deque([pkg for pkg in all_packages if indegree[pkg] == 0 and graph[pkg]]

    build_order = []
    
    while queue:
        pkg = queue.popleft()
        build_order.append(pkg)
        
        for dependent in graph[pkg]:
            indegree[dependent] -= 1
            if indegree[dependent] == 0:
                queue.append(dependent)

    for package in [pkg for pkg in all_packages if indegree[pkg] == 0 and not graph[pkg]]:
        build_order.append(package)

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
    # if len(build_order) != len(all_packages):
    #     raise ValueError("Cyclic dependency detected in the package dependencies, build_order: {}, all_packagees: {}.".format(len(build_order), len(all_packages)))

    return build_order

def main(root_dir):

    packages, package_paths = find_packages(root_dir)

    try:
        build_order = topological_sort(packages)

        for pkg in build_order:
            print(package_paths[pkg])

    except ValueError as e:
        print("Error:", e)

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python build_order.py <root_directory>")
    else:
        main(sys.argv[1])
