%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "parser.tab.h"
    void token(char* s){fprintf(stderr,"%-10s %s\n",yytext,s);}

%}

%option noyywrap
%option yylineno

%%
"if" {token("IF");return IF;}
"else" {token("ELSE");return ELSE;}
"while" {token("WHILE");return WHILE;}
"for" {token("FOR");return FOR;}

"<"|">"|"<="|">="|"=="|"!=" {token("RELOP");yylval.s=strdup(yytext);return RELOP;}
[a-zA-Z_][a-zA-Z0-9_]* {token("ID");yylval.s=strdup(yytext);return ID;}
[0-9]+(\.[0-9]+)? {token("NUM");yylval.s=strdup(yytext);return NUM;}

[+-/*] {token("Arithmetic");return yytext[0];}
"=" {token("Equal To");return '=';}
[(){};] {token("Special");return yytext[0];}

[ \t\r\n]+ ;
. {token("invalid");}
%%