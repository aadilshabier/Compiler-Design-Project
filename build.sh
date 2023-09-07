#! /usr/bin/env sh

set -xe

flex++ lexer.l
c++ lex.yy.cc
./a.out
