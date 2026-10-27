%{
#include <stdio.h>
#include <string.h>
#include "parser.tab.h"

void tok(char *kind) { fprintf(stderr, "%-10s %s\n", yytext, kind); }
%}

%option noyywrap
%option yylineno

%%
"if"                    { tok("keyword"); return IF; }
"else"                  { tok("keyword"); return ELSE; }
"while"                 { tok("keyword"); return WHILE; }
"for"                   { tok("keyword"); return FOR; }

"<"|">"|"<="|">="|"=="|"!="  { tok("relational operator"); yylval.s = strdup(yytext); return RELOP; }

[a-zA-Z_][a-zA-Z0-9_]*  { tok("identifier"); yylval.s = strdup(yytext); return ID; }
[0-9]+                  { tok("constant"); yylval.s = strdup(yytext); return NUM; }

[-+*/]                  { tok("arithmetic operator"); return yytext[0]; }
"="                     { tok("assignment operator"); return '='; }
[(){};]                 { tok("special symbol"); return yytext[0]; }

[ \t\r\n]+              ;
.                       { tok("invalid character"); }
%%

