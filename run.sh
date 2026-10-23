#!/bin/sh
IN=${1:-input.txt}

bison -d parser.y || exit 1
flex lexer.l || exit 1
gcc parser.tab.c lex.yy.c -o icg || exit 1
gcc opt.c -o opt || exit 1
gcc gen.c -o gen || exit 1

echo "===== INPUT ====="
cat $IN
echo

echo "===== (a) TOKENS + (b) SYNTAX CHECK ====="
./icg < $IN > tac.txt || exit 1
echo
echo "===== (c) THREE ADDRESS CODE ====="
cat tac.txt
echo
echo "===== (d) OPTIMIZED CODE ====="
./opt < tac.txt > opt.txt
cat opt.txt
echo
echo "===== (e) TARGET CODE ====="
./gen < opt.txt
