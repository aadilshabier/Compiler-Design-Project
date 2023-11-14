#! /usr/bin/env sh


# Check if an argument was provided
if [ $# -lt 1 ]; then
    echo "Usage: ./build.sh <test_file_name.c>"
    exit 1
fi

set -xe

bison -d -o parser.cpp parser.y
flex -o lexer.cpp lexer.l
c++ -Wno-write-strings lexer.cpp parser.cpp symbol_table.cpp
./a.out $1
