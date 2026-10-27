%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(char *s);
extern int yylineno;
extern char *yytext;

int tc = 1, lab = 1;

char *binop(char *op, char *a, char *b) {
    char t[10];
    sprintf(t, "t%d", tc++);
    printf("%s = %s %s %s\n", t, a, op, b);
    return strdup(t);
}

char *text(char *a, char *op, char *b) {
    char s[100];
    sprintf(s, "%s %s %s", a, op, b);
    return strdup(s);
}
%}

%union { char *s; int n; }
%token <s> ID NUM RELOP
%token IF ELSE WHILE FOR
%type <s> E COND STEP
%type <n> IFH

%nonassoc LOW
%nonassoc ELSE
%left '+' '-'
%left '*' '/'
%define parse.error detailed

%%
PROG : LIST                 { fprintf(stderr, "\nSyntax is valid\n"); }
     ;

LIST : LIST STMT
     | STMT
     ;

STMT : ID '=' E ';'         { printf("%s = %s\n", $1, $3); }
     | '{' LIST '}'
     | IFH STMT %prec LOW   { printf("L%d:\n", $1 + 1); }
     | IFH STMT ELSE        { $<n>$ = lab++; printf("goto L%d\nL%d:\n", $<n>$, $1 + 1); }
       STMT                 { printf("L%d:\n", $<n>4); }
     | WHILE                { $<n>$ = lab; lab += 3; printf("L%d:\n", $<n>$); }
       '(' COND ')'         { printf("if %s goto L%d\ngoto L%d\nL%d:\n", $4, $<n>2 + 1, $<n>2 + 2, $<n>2 + 1); }
       STMT                 { printf("goto L%d\nL%d:\n", $<n>2, $<n>2 + 2); }
     | FOR '(' ID '=' E ';' { printf("%s = %s\n", $3, $5); $<n>$ = lab; lab += 3; printf("L%d:\n", $<n>$); }
       COND ';' STEP ')'    { printf("if %s goto L%d\ngoto L%d\nL%d:\n", $8, $<n>7 + 1, $<n>7 + 2, $<n>7 + 1); }
       STMT                 { printf("%s\ngoto L%d\nL%d:\n", $10, $<n>7, $<n>7 + 2); }
     ;

IFH  : IF '(' COND ')'      { $$ = lab; lab += 2; printf("if %s goto L%d\ngoto L%d\nL%d:\n", $3, $$, $$ + 1, $$); }
     ;

COND : E RELOP E            { $$ = text($1, $2, $3); }
     ;

STEP : ID '=' ID '+' NUM    { $$ = text($1, "=", text($3, "+", $5)); }
     | ID '=' ID '-' NUM    { $$ = text($1, "=", text($3, "-", $5)); }
     ;

E    : E '+' E              { $$ = binop("+", $1, $3); }
     | E '-' E              { $$ = binop("-", $1, $3); }
     | E '*' E              { $$ = binop("*", $1, $3); }
     | E '/' E              { $$ = binop("/", $1, $3); }
     | '(' E ')'            { $$ = $2; }
     | ID
     | NUM
     ;
%%

void yyerror(char *s)
{
    fprintf(stderr,
            "\nSyntax Error at line %d near '%s'\nReason: %s\n",
            yylineno, yytext, s);
    exit(1);
}

int main() {
    yyparse();
    return 0;
}
