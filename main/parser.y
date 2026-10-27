%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    extern int yylineno;
    extern char *yytext;

    int lab = 1;
    int tc = 1;

    void yyerror (const char* s);
    int yylex();

    char* text( char* op, char* a, char*b){
        char s[100];
        sprintf(s,"%s %s %s\n",a,op,b);
        return strdup(s);
    }
    
    char* binop( char* op, char* a, char*b){
        char t[10];
        sprintf(t,"t%d",tc++);
        printf("%s = %s %s %s\n",t,a,op,b);
        return strdup(t);
    }
    
%}

%union {int n; char*s;}
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
PROG : LIST {fprintf(stderr,"Successfully parsed!\n");}
     ;

LIST : LIST STMT | STMT ;

IFH : IF '(' COND ')' {$$=lab;lab+=2;printf("if %s goto L%d\ngoto L%d\nL%d: \n",$3, $$, $$+1, $$);} ;


STMT : ID '=' E ';' {printf("%s = %s\n",$1,$3);} 

    | '{' LIST '}'

     | IFH STMT %prec LOW {printf("L%d: \n",$1+1);}
     | IFH STMT ELSE{$<n>$=lab++;printf("goto L%d\n L%d \n",$<n>$,$1+1);}
            STMT {printf("L%d: \n",$<n>4);}
     |

     WHILE {$<n>$=lab;lab+=3;printf("L%d: \n",$<n>$);}
     '(' COND ')' {printf("if %s goto L%d\ngoto L%d\nL%d: \n",$4,$<n>2+1,$<n>2+2,$<n>2+1);}
     STMT {printf("goto L%d\nL%d: \n",$<n>2,$<n>2+2);}
     |

     FOR '(' ID '=' NUM ';' {$<n>$=lab;lab+=3;printf("%s = %s\nL%d: \n",$3,$5,$<n>$);}
     COND ';' STEP ')' {int x = $<n>7; printf("if %s goto L%d\ngoto L%d\nL%d: \n",$8, x+1, x+2,x+1);}
     STMT {int x = $<n>7; printf("%s\ngoto L%d\nL%d: \n", $10, x, x+2);}
     ;


E:  E '+' E {$$ = binop("+",$1,$3);} |
    E '-' E {$$ = binop("-",$1,$3);} |
    E '*' E {$$ = binop("*",$1,$3);} |
    E '/' E {$$ = binop("/",$1,$3);} |
ID|NUM
;
STEP: ID '=' E '+' E {$$=text("=",$1,text("+",$3,$5));}
    | 
     ID '=' E '-' E {$$=text("=",$1,text("-",$3,$5));}
;
COND: E RELOP E {$$=text($2,$1,$3);}
;
%%

void yyerror(const char*s){
    fprintf(stderr,"%s, %d, %s.\n",s,yylineno,yytext);
    exit(1);
}
int main(){
    yyparse();
    return 0;
}