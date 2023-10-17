#! /usr/bin/env sh

# Check if an argument was provided
if [ $# -lt 1 ]; then
    echo "Usage: ./build.sh <test_file_name.c>"
    exit 1
fi


set -xe

flex++ lexer.l
c++ lex.yy.cc
./a.out $1
