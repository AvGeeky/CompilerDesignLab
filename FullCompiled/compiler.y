

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int yylex(void);

void yyerror(const char *s)
{
    printf("Syntax Error: %s\n", s);
}

struct Quad {
    char op[10], arg1[20], arg2[20], res[20];
    int state;
} q[200];

int q_idx = 0;
int t_cnt = 0;
int l_cnt = 0;
int loop_s = -1;
int loop_e = -1;
int n_loops = 0;

void emit(char *op, char *a1, char *a2, char *res) {
    if (q_idx >= 200) {
        fprintf(stderr, "Too many TAC instructions\n");
        exit(1);
    }
    strcpy(q[q_idx].op, op);
    strcpy(q[q_idx].arg1, a1);
    strcpy(q[q_idx].arg2, a2);
    strcpy(q[q_idx].res, res);
    q[q_idx].state = 0;
    q_idx++;
}

char *new_temp(void) {
    static char b[20];
    snprintf(b, sizeof(b), "t%d", t_cnt++);
    return b;
}

char *new_label(void) {
    static char b[20];
    snprintf(b, sizeof(b), "L%d", l_cnt++);
    return b;
}

int is_num(char *s) {
    if (s[0] == '\0') return 0;
    for (int i = 0; s[i]; i++)
        if (!isdigit(s[i])) return 0;
    return 1;
}

void binop(char *op, char *a, char *b, char *res) {
    char *t = new_temp();
    emit(op, a, b, t);
    strcpy(res, t);
}

char loop_start_label[20], loop_end_label[20];
char if_false_label[20], if_end_label[20];
%}

%union {
    char str[20];
}

%token <str> ID NUM RELOP
%token WHILE IF ELSE FOR
%type <str> E COND ADDOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%left '+' '-'
%left '*' '/'

%%

PROGRAM : STMT_LIST { printf("\n[Part B] Syntax Analysis Successful: Valid Syntax!\n"); };

STMT_LIST : STMT_LIST STMT | STMT;

BLOCK : '{' STMT_LIST '}' | STMT;

STMT : ASSIGN_STMT
    | WHILE_STMT
    | FOR_STMT
    | IF_STMT;

ASSIGN_STMT
    : ID '=' E ';'
      { emit("=", $3, "", $1); }
    ;

WHILE_STMT : WHILE
    {
        strcpy(loop_start_label, new_label());
        emit("label", "", "", loop_start_label);
        loop_s = q_idx - 1;
    }
    '(' COND ')'
    {
        strcpy(loop_end_label, new_label());
        emit("ifFalse", $4, "", loop_end_label);
    }
    BLOCK
    {
        emit("goto", "", "", loop_start_label);
        emit("label", "", "", loop_end_label);
        loop_e = q_idx - 1;
        n_loops++;
    }
    ;

/* Position	Symbol	Meaning
$1	FOR	for keyword
$2	'('	Opening parenthesis
$3	ASSIGN_STMT	Initialization, e.g. i = 0;
$4	Action A	Saves loop-start label
$5	COND	Condition, e.g. i < 10
$6	';'	Second semicolon
$7	Action B	Saves loop-exit label
$8	ID	Increment variable, e.g. i
$9	'='	Assignment operator
$10	ID	Variable in increment expression, e.g. i
$11	ADDOP	+ or -
$12	NUM	Increment amount, e.g. 1
$13	')'	Closing parenthesis
$14	BLOCK	Loop body
$15	Action C	Generates increment, jump, and exit label 
FOR_STMT
    : FOR '(' ASSIGN_STMT
      //{  Action A  }
      //COND ';'
      //{  Action B  }
      //ID '=' ID ADDOP NUM ')' BLOCK
      //{  Action C  }
    ;
*/

FOR_STMT : FOR '(' ASSIGN_STMT
    {
        strcpy(loop_start_label, new_label());
        emit("label", "", "", loop_start_label);
        loop_s = q_idx - 1;
    }
    COND ';'
    {
        strcpy(loop_end_label, new_label());
        emit("ifFalse", $5, "", loop_end_label);
    }
    ID '=' ID ADDOP NUM ')' BLOCK
    {
        char *t = new_temp();
        emit($11, $10, $12, t);
        emit("=", t, "", $8);
        emit("goto", "", "", loop_start_label);
        emit("label", "", "", loop_end_label);
        loop_e = q_idx - 1;
        n_loops++;
    }
    ;

ADDOP
    : '+' { strcpy($$, "+"); }
    | '-' { strcpy($$, "-"); }
    ;

COND : E RELOP E { binop($2, $1, $3, $$); } ; 


IF_STMT
    : IF_PREFIX BLOCK %prec LOWER_THAN_ELSE
      {
          emit("label", "", "", if_false_label);
      }
    | IF_PREFIX BLOCK ELSE
      {
          strcpy(if_end_label, new_label());
          emit("goto", "", "", if_end_label);
          emit("label", "", "", if_false_label);
      }
      BLOCK
      {
          emit("label", "", "", if_end_label);
      }
    ;

IF_PREFIX
    : IF '(' COND ')'
      {
          strcpy(if_false_label, new_label());
          emit("ifFalse", $3, "", if_false_label);
      }
    ;


E
    : E '+' E { binop("+", $1, $3, $$); }
    | E '-' E { binop("-", $1, $3, $$); }
    | E '*' E { binop("*", $1, $3, $$); }
    | E '/' E { binop("/", $1, $3, $$); }
    | '(' E ')' { strcpy($$, $2); }
    | ID { strcpy($$, $1); }
    | NUM { strcpy($$, $1); }
    ;

%%

void print_quad(struct Quad x) {
    if (strcmp(x.op, "label") == 0)
        printf("%s:\n", x.res);
    else if (strcmp(x.op, "goto") == 0)
        printf("    goto %s\n", x.res);
    else if (strcmp(x.op, "ifFalse") == 0)
        printf("    ifFalse %s goto %s\n", x.arg1, x.res);
    else if (strcmp(x.op, "=") == 0)
        printf("    %s = %s\n", x.res, x.arg1);
    else
        printf("    %s = %s %s %s\n", x.res, x.arg1, x.op, x.arg2);
}

int count_defs(char *v) {
    if (v[0] == '\0' || is_num(v)) return 0;
    int c = 0;
    for (int i = loop_s; i <= loop_e; i++)
        if (i >= 0 && q[i].state == 0 && strcmp(q[i].res, v) == 0)
            c++;
    return c;
}

int is_movable(char *op) {
    return strcmp(op, "+") == 0 ||
           strcmp(op, "-") == 0 ||
           strcmp(op, "*") == 0 ||
           strcmp(op, "<<") == 0;
}

void optimize(void) {
    for (int i = 0; i < q_idx; i++) {
        char *op = q[i].op;
        char *a1 = q[i].arg1;
        char *a2 = q[i].arg2;

        if (is_num(a1) && is_num(a2)) {
            int v1 = atoi(a1), v2 = atoi(a2), ans = 0;
            if (strcmp(op, "+") == 0) ans = v1 + v2;
            else if (strcmp(op, "-") == 0) ans = v1 - v2;
            else if (strcmp(op, "*") == 0) ans = v1 * v2;
            else if (strcmp(op, "/") == 0 && v2 != 0) ans = v1 / v2;
            else continue;
            strcpy(op, "=");
            snprintf(a1, sizeof(q[i].arg1), "%d", ans);
            strcpy(a2, "");
        } else if ((strcmp(op, "+") == 0 || strcmp(op, "-") == 0) &&
                   strcmp(a2, "0") == 0) {
            strcpy(op, "=");
            strcpy(a2, "");
        } else if ((strcmp(op, "*") == 0 || strcmp(op, "/") == 0) &&
                   strcmp(a2, "1") == 0) {
            strcpy(op, "=");
            strcpy(a2, "");
        } else if (strcmp(op, "*") == 0 && strcmp(a2, "0") == 0) {
            strcpy(op, "=");
            strcpy(a1, "0");
            strcpy(a2, "");
        } else if (strcmp(op, "+") == 0 && strcmp(a1, "0") == 0) {
            strcpy(op, "=");
            strcpy(a1, a2);
            strcpy(a2, "");
        } else if (strcmp(op, "*") == 0 && strcmp(a1, "1") == 0) {
            strcpy(op, "=");
            strcpy(a1, a2);
            strcpy(a2, "");
        } else if (strcmp(op, "*") == 0 && strcmp(a2, "2") == 0) {
            strcpy(op, "+");
            strcpy(a2, a1);
        } else if (strcmp(op, "*") == 0 && strcmp(a2, "4") == 0) {
            strcpy(op, "<<");
            strcpy(a2, "2");
        } else if (strcmp(op, "*") == 0 && strcmp(a2, "8") == 0) {
            strcpy(op, "<<");
            strcpy(a2, "3");
        }

        if (strcmp(op, "=") == 0 &&
            q[i].res[0] == 't' &&
            isdigit((unsigned char)q[i].res[1])) {
            for (int j = i + 1; j < q_idx; j++) {
                if (strcmp(q[j].arg1, q[i].res) == 0)
                    strcpy(q[j].arg1, a1);
                if (strcmp(q[j].arg2, q[i].res) == 0)
                    strcpy(q[j].arg2, a1);
            }
            q[i].state = 1;
        }
    }

    if (n_loops == 1 && loop_s >= 0 && loop_e > loop_s) {
        for (int i = loop_s + 1; i < loop_e; i++) {
            if (q[i].state == 0 &&
                is_movable(q[i].op) &&
                q[i].res[0] == 't' &&
                isdigit((unsigned char)q[i].res[1]) &&
                count_defs(q[i].arg1) == 0 &&
                count_defs(q[i].arg2) == 0 &&
                count_defs(q[i].res) == 1) {
                q[i].state = 2;
            }
        }
    }

    printf("\n--- [Part D] Optimized Three-Address Code ---\n");
    for (int i = 0; i < q_idx; i++) {
        if (i == loop_s && n_loops == 1) {
            for (int j = loop_s + 1; j < loop_e; j++)
                if (q[j].state == 2) print_quad(q[j]);
        }
        if (q[i].state == 0) print_quad(q[i]);
    }
}

int reg = 0;
char last_relop[10] = "";

void gen_asm(struct Quad x) {
    char *op = x.op;

    if (strcmp(op, "label") == 0) {
        printf("%s:\n", x.res);
    } else if (strcmp(op, "goto") == 0) {
        printf("    JMP %s\n", x.res);
    } else if (strcmp(op, "ifFalse") == 0) {
        char *j = "JE";
        if (strcmp(last_relop, "<") == 0) j = "JGE";
        else if (strcmp(last_relop, ">") == 0) j = "JLE";
        else if (strcmp(last_relop, "<=") == 0) j = "JG";
        else if (strcmp(last_relop, ">=") == 0) j = "JL";
        else if (strcmp(last_relop, "==") == 0) j = "JNE";
        else if (strcmp(last_relop, "!=") == 0) j = "JE";
        printf("    %s %s\n", j, x.res);
    } else if (strcmp(op, "=") == 0) {
        printf("    MOV R%d, %s\n", reg, x.arg1);
        printf("    MOV %s, R%d\n", x.res, reg);
        reg++;
    } else {
        int is_cmp = 0;
        printf("    MOV R%d, %s\n", reg, x.arg1);
        if (strcmp(op, "+") == 0) printf("    ADD R%d, %s\n", reg, x.arg2);
        else if (strcmp(op, "-") == 0) printf("    SUB R%d, %s\n", reg, x.arg2);
        else if (strcmp(op, "*") == 0) printf("    MUL R%d, %s\n", reg, x.arg2);
        else if (strcmp(op, "/") == 0) printf("    DIV R%d, %s\n", reg, x.arg2);
        else if (strcmp(op, "<<") == 0) printf("    SHL R%d, %s\n", reg, x.arg2);
        else {
            printf("    CMP R%d, %s\n", reg, x.arg2);
            is_cmp = 1;
            strcpy(last_relop, op);
        }
        if (!is_cmp) printf("    MOV %s, R%d\n", x.res, reg);
        reg++;
    }
}

void codegen(void) {
    printf("\n--- [Part E] Target Assembly Code ---\n");
    for (int i = 0; i < q_idx; i++) {
        if (i == loop_s && n_loops == 1) {
            for (int j = loop_s + 1; j < loop_e; j++)
                if (q[j].state == 2) gen_asm(q[j]);
        }
        if (q[i].state == 0) gen_asm(q[i]);
    }
}



int main(void) {
    printf("--- [Part A] Lexical Analysis (Tokens) ---\n");
    yyparse();

    printf("\n--- [Part C] Generated Three-Address Code ---\n");
    for (int i = 0; i < q_idx; i++)
        print_quad(q[i]);

    optimize();
    codegen();
    return 0;
}