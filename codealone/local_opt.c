
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int isnum(char *s) {
    char *end;
    strtod(s, &end);
    return *s && *end == '\0';
}

int main() {
    char line[200], d[30], a[30], op[10], b[30];

    while (fgets(line, sizeof(line), stdin)) {
        if (sscanf(line, "%29s = %29s %9s %29s",
                   d, a, op, b) != 4) {
            printf("%s", line);
            continue;
        }

        // Constant folding
        if (isnum(a) && isnum(b)) {
            double x = atof(a), y = atof(b), r;

            if (!strcmp(op, "+")) r = x + y;
            else if (!strcmp(op, "-")) r = x - y;
            else if (!strcmp(op, "*")) r = x * y;
            else if (!strcmp(op, "/") && y != 0) r = x / y;
            else {
                printf("%s", line);
                continue;
            }

            printf("%s = %.10g\n", d, r);
        }

        // Algebraic simplification
        else if ((!strcmp(op, "+") || !strcmp(op, "-"))
                 && !strcmp(b, "0"))
            printf("%s = %s\n", d, a);

        else if (!strcmp(op, "+") && !strcmp(a, "0"))
            printf("%s = %s\n", d, b);

        else if ((!strcmp(op, "*") || !strcmp(op, "/"))
                 && !strcmp(b, "1"))
            printf("%s = %s\n", d, a);

        else if (!strcmp(op, "*") && !strcmp(a, "1"))
            printf("%s = %s\n", d, b);

        else if (!strcmp(op, "*") &&
                 (!strcmp(a, "0") || !strcmp(b, "0")))
            printf("%s = 0\n", d);

        // Strength reduction
        else if (!strcmp(op, "*") && !strcmp(b, "2"))
            printf("%s = %s + %s\n", d, a, a);

        else if (!strcmp(op, "*") && !strcmp(b, "4"))
            printf("%s = %s << 2\n", d, a);

        else if (!strcmp(op, "*") && !strcmp(b, "8"))
            printf("%s = %s << 3\n", d, a);

        else
            printf("%s = %s %s %s\n", d, a, op, b);
    }

    return 0;
}
