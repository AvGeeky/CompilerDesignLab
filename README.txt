lexer.l    (a) tokens
parser.y   (b) syntax check + (c) three address code
opt.c      (d) constant folding, algebraic simplification, strength reduction, code motion
gen.c      (e) target code
run.sh     (f) integration

Run all:      sh run.sh            or   sh run.sh tests/for.txt

Run one by one:
  bison -d parser.y
  flex lexer.l
  gcc parser.tab.c lex.yy.c -o icg
  gcc opt.c -o opt
  gcc gen.c -o gen
  ./icg < input.txt > tac.txt
  ./opt < tac.txt > opt.txt
  ./gen < opt.txt

Only lex/yacc available:  yacc -d -b parser parser.y   and   lex lexer.l
