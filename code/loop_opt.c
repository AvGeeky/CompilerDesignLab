
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

char lines[300][200];
int moved[300], N;

int istemp(char *s) {
    return s[0] == 't' && isdigit((unsigned char)s[1]);
}

int assigned(char *v, int start, int end) {
    char d[30], eq[10];

    for (int i = start + 1; i < end; i++) {
        if (sscanf(lines[i], "%29s %9s", d, eq) == 2 &&
            !strcmp(eq, "=") && !strcmp(d, v))
            return 1;
    }
    return 0;
}

int main() {
    char buf[200], label[30], target[30];
    int start = -1, end = -1;

    while (fgets(buf, sizeof(buf), stdin) && N < 300) {
        strcpy(lines[N++], buf);
    }

    // Find loop start label
    for (int i = 0; i < N; i++) {
        if (sscanf(lines[i], "%29[^:]:", label) == 1 &&
            strchr(lines[i], ':')) {

            // Find a backward goto to this label
            for (int j = i + 1; j < N; j++) {
                if (sscanf(lines[j], "goto %29s", target) == 1 &&
                    !strcmp(target, label)) {
                    start = i;
                    end = j;
                }
            }
        }
    }

    if (start < 0 || end < 0) {
        for (int i = 0; i < N; i++)
            printf("%s", lines[i]);
        return 0;
    }

    // Find invariant temporary calculations
    for (int i = start + 1; i < end; i++) {
        char d[30], eq[10], a[30], op[10], b[30];

        if (sscanf(lines[i], "%29s %9s %29s %9s %29s",
                   d, eq, a, op, b) != 5)
            continue;

        if (strcmp(eq, "=") || !istemp(d))
            continue;

        // Avoid division for this simple version
        if (!strcmp(op, "/"))
            continue;

        // Operands must not be assigned inside the loop
        if (assigned(a, start, end) ||
            assigned(b, start, end))
            continue;

        moved[i] = 1;
    }

    // Print moved calculations before the loop label
    for (int i = 0; i < N; i++) {
        if (i == start) {
            for (int j = start + 1; j < end; j++)
                if (moved[j])
                    printf("%s", lines[j]);
        }

        if (!moved[i])
            printf("%s", lines[i]);
    }

    return 0;
}
