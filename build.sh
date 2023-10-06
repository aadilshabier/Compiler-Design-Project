#! /usr/bin/env sh

set -xe

# Check if an argument was provided
if [ $# -lt 1 ]; then
    echo "Usage: ./build.sh <test_file_name.c>"
    exit 1
fi

flex++ lexer.l
c++ lex.yy.cc
./a.out ./test/$1
