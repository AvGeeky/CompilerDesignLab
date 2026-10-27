#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

char w[300][6][30];
int n[300], pos[300], N = 0;

int isnum(char *s) {
    if (!*s) return 0;

    char *end;
    strtod(s, &end);

    return end != s && *end == '\0';
}

int istemp(char *s) { return s[0] == 't' && isdigit(s[1]); }
int is(int i, int k, char *s) { return strcmp(w[i][k], s) == 0; }

void copy(int i, char *v) {
    char t[30];
    strcpy(t, v);
    strcpy(w[i][2], t);
    n[i] = 3;
}

void simplify(int i) {
    if (n[i] != 5) return;
    char *a = w[i][2], *op = w[i][3], *b = w[i][4];

    // Constant folding
    if (isnum(a) && isnum(b)) {
        double x = atof(a), y = atof(b), r;

        if (!strcmp(op, "+")) r = x + y;
        else if (!strcmp(op, "-")) r = x - y;
        else if (!strcmp(op, "*")) r = x * y;
        else if (!strcmp(op, "/") && y != 0) r = x / y;
        else return;

        char s[30];
        sprintf(s, "%.10g", r);
        copy(i, s);
    }
    // Algebraic simplification
    else if ((!strcmp(op, "+") || !strcmp(op, "-")) && !strcmp(b, "0")) copy(i, a);
    else if (!strcmp(op, "+") && !strcmp(a, "0"))                       copy(i, b);
    else if ((!strcmp(op, "*") || !strcmp(op, "/")) && !strcmp(b, "1")) copy(i, a);
    else if (!strcmp(op, "*") && !strcmp(a, "1"))                       copy(i, b);
    else if (!strcmp(op, "*") && (!strcmp(a, "0") || !strcmp(b, "0")))  copy(i, "0");
    // Strength reduction
    else if (!strcmp(op, "*") && !strcmp(b, "2")) { strcpy(op, "+");  strcpy(b, a); }
    else if (!strcmp(op, "*") && !strcmp(b, "4")) { strcpy(op, "<<"); strcpy(b, "2"); }
    else if (!strcmp(op, "*") && !strcmp(b, "8")) { strcpy(op, "<<"); strcpy(b, "3"); }
}

// Code motion (loop invariant)
int assigned(char *v, int s, int e) {
    for (int j = s + 1; j < e; j++)
        if ((pos[j] < 0 || pos[j] > s) && n[j] >= 3 && is(j, 1, "=") && is(j, 0, v)) return 1;
    return 0;
}

void motion(int s) {
    char name[30];
    strcpy(name, w[s][0]);
    name[strlen(name) - 1] = '\0';

    int e = -1;
    for (int j = s + 1; j < N; j++)
        if (n[j] == 2 && is(j, 0, "goto") && is(j, 1, name)) e = j;
    if (e < 0) return;

    for (int k = s + 1; k < e; k++) {
        if (pos[k] >= 0 || n[k] < 3 || !is(k, 1, "=") || !istemp(w[k][0])) continue;
        if (n[k] == 5 && is(k, 3, "/")) continue;
        if (assigned(w[k][2], s, e)) continue;
        if (n[k] == 5 && assigned(w[k][4], s, e)) continue;
        pos[k] = s;
    }
}

/* Dead code elimination (add-on): remove temps that are never used
int used(char *v) {
    for (int j = 0; j < N; j++)
        for (int k = 1; k < n[j]; k++)
            if (is(j, k, v)) return 1;
    return 0;
}

void deadcode() {
    for (int i = N - 1; i >= 0; i--)
        if (n[i] >= 3 && is(i, 1, "=") && istemp(w[i][0]) && !used(w[i][0]))
            n[i] = 0;
}
*/

void print(int i) {
    for (int k = 0; k < n[i]; k++)
        printf(k < n[i] - 1 ? "%s " : "%s\n", w[i][k]);
}

int main() {
    char buf[200];
    while (fgets(buf, 200, stdin)) {
        char *p = strtok(buf, " \t\r\n");
        if (!p) continue;
        n[N] = 0;
        while (p) { strcpy(w[N][n[N]++], p); p = strtok(NULL, " \t\r\n"); }
        pos[N] = -1;
        N++;
    }

    for (int i = 0; i < N; i++)
        simplify(i);

    // deadcode();

    for (int i = N - 1; i >= 0; i--)
        if (n[i] == 1) motion(i);

    for (int i = 0; i < N; i++) {
        for (int k = 0; k < N; k++)
            if (pos[k] == i) print(k);
        if (pos[i] < 0) print(i);
    }
    return 0;
}