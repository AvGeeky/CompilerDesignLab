%{
/* ======================= PART (a): LEX SPECIFICATION =======================
   A lex file has 3 sections separated by %% :
       1) DEFINITIONS   (this part: C code between %{ and %})
       2) RULES         (pattern   { C action })
       3) USER CODE     (extra C functions, after the 2nd %%)
   Lex reads the input text and chops it into TOKENS (words of the language).
   Each time yacc calls yylex(), lex finds the next token and "return"s its type.
*/

#include <stdio.h>      /* gives us printf()                                    */
#include <string.h>     /* gives us strcpy()                                    */
#include "y.tab.h"      /* made by "yacc -d": has the token names WHILE, ID,    */
                        /* NUM, RELOP ... and the variable yylval               */
%}

%%

"while"   { printf("Token: KEYWORD (%s)\n", yytext);   /* yytext = the text lex just matched   */
            return WHILE; }                            /* tell yacc "I found a WHILE token"    */

"if"      { printf("Token: KEYWORD (%s)\n", yytext); return IF; }     /* same idea for if   */
"else"    { printf("Token: KEYWORD (%s)\n", yytext); return ELSE; }   /* same idea for else */
"for"     { printf("Token: KEYWORD (%s)\n", yytext); return FOR; }    /* same idea for for  */

"<"|">"|"<="|">="|"=="|"!="   {                        /* any ONE of these 6 relational operators */
            printf("Token: RELOP (%s)\n", yytext);     /* show the token                          */
            strcpy(yylval.str, yytext);                /* yylval = value sent to yacc; save "<"   */
            return RELOP; }                            /* token type = RELOP                      */

[a-zA-Z_][a-zA-Z0-9_]*   {                             /* a letter or _ followed by letters/digits/_ */
            printf("Token: ID (%s)\n", yytext);        /* it is an identifier (variable name)     */
            strcpy(yylval.str, yytext);                /* send the name (e.g. "m") to yacc        */
            return ID; }                               /* token type = ID                         */

[0-9]+    {                                            /* one or more digits                      */
            printf("Token: NUM (%s)\n", yytext);       /* it is a number                          */
            strcpy(yylval.str, yytext);                /* send the digits (e.g. "16") to yacc     */
            return NUM; }                              /* token type = NUM                        */

"+"|"-"|"*"|"/"|"="|"("|")"|"{"|"}"|";"   {           /* single-character symbols                */
            printf("Token: SYMBOL (%s)\n", yytext);    /* show the token                          */
            return yytext[0]; }                        /* the token type is the character itself  */

[ \t\r\n]+   { /* spaces, tabs, newlines: do nothing (ignore them) */ }

.            { printf("Unknown character: %s\n", yytext); }   /* anything else = error message    */

%%

int yywrap() {   /* lex calls this at end of input                                    */
    return 1;    /* 1 means "no more input files, stop"                               */
}