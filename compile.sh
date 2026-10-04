#!/bin/bash

if [ "$1" == "-r" ]; then
    BUILD_TYPE="Release"
elif [ "$1" == "-d" ]; then
    BUILD_TYPE="Debug"
else
    echo "Usage: compile.sh [-r] [-d]"
    echo "  -r: Release build"
    echo "  -d: Debug build"
    exit 1
fi

cd build/ && cmake -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../  &&  make && ./minepaint


