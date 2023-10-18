#! /usr/bin/env sh


# Check if an argument was provided
if [ $# -lt 1 ]; then
    echo "Usage: ./build.sh <test_file_name.c>"
    exit 1
fi

set -xe

bison -d -o parser.cpp parser.y
flex -o lexer.cpp lexer.l
c++ lexer.cpp parser.cpp
./a.out $1
