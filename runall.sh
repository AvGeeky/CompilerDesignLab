
#!/bin/bash

# Compile everything once
bison -d parser.y || exit 1
flex lexer.l || exit 1
gcc parser.tab.c lex.yy.c -o icg || exit 1
gcc opt.c -o opt || exit 1
gcc gen.c -o gen || exit 1

# Run every test case
for IN in tests/*.txt; do
    [ -f "$IN" ] || continue

    echo
    echo "########################################"
    echo "TEST CASE: $IN"
    echo "########################################"

    echo
    echo "===== INPUT ====="
    cat "$IN"

    echo
    echo "===== (a) TOKENS + (b) SYNTAX CHECK ====="
    if ! ./icg < "$IN" > tac.txt; then
        echo "FAILED: Syntax checking / TAC generation"
        continue
    fi

    echo
    echo "===== (c) THREE ADDRESS CODE ====="
    cat tac.txt

    echo
    echo "===== (d) OPTIMIZED CODE ====="
    if ! ./opt < tac.txt > opt.txt; then
        echo "FAILED: Optimization"
        continue
    fi
    cat opt.txt

    echo
    echo "===== (e) TARGET CODE ====="
    if ! ./gen < opt.txt; then
        echo "FAILED: Target code generation"
        continue
    fi

    echo
    echo "===== TEST COMPLETED ====="
done
