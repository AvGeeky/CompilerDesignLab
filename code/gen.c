#include <stdio.h>
#include <string.h>

char *jump(char *op) {
    if (!strcmp(op, "<"))  return "JL";
    if (!strcmp(op, ">"))  return "JG";
    if (!strcmp(op, "<=")) return "JLE";
    if (!strcmp(op, ">=")) return "JGE";
    if (!strcmp(op, "==")) return "JE";
    return "JNE";
}

char *instr(char *op) {
    if (!strcmp(op, "+")) return "ADD";
    if (!strcmp(op, "-")) return "SUB";
    if (!strcmp(op, "*")) return "MUL";
    if (!strcmp(op, "/")) return "DIV";
    return "SHL";
}

int main() {
    char l[200], d[30], a[30], op[10], b[30], lab[30];
    while (fgets(l, 200, stdin)) {
        if (sscanf(l, "if %s %s %s goto %s", a, op, b, lab) == 4) {
            printf("CMP %s, %s\n", a, b);
            printf("%s %s\n", jump(op), lab);
        }
        else if (sscanf(l, "goto %s", lab) == 1)
            printf("JMP %s\n", lab);
        else if (strchr(l, ':'))
            printf("%s", l);
        else if (sscanf(l, "%s = %s %s %s", d, a, op, b) == 4) {
            printf("MOV R0, %s\n", a);
            printf("%s R0, %s\n", instr(op), b);
            printf("MOV %s, R0\n", d);
        }
        else if (sscanf(l, "%s = %s", d, a) == 2) {
            printf("MOV R0, %s\n", a);
            printf("MOV %s, R0\n", d);
        }
    }
    return 0;
}
