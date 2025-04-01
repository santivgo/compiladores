%{
    #include <stdio.h>
%}
INTEGER [0-9]
DECIMAL ({INTEGER}?\.{INTEGER}+)
NUM ({INTEGER}+|{DECIMAL})
SIMB [-+*/=]
DESC [ \n\t]
MATHOP ({NUM}({SIMB}{NUM})+)

%%
 /*tokens*/
{INTEGER} {printf("achei um número integer: %s\n", yytext);}
{DECIMAL} {printf("achei um número decimal: %s\n", yytext);}
{NUM} {printf("achei um número: %s\n", yytext);}
{SIMB} {printf("achei um símbolo: %s\n", yytext);}
{MATHOP} {printf("achei uma operação: %s\n", yytext);}
{DESC} {printf("achei uma simbolo desconhecido: %s\n", yytext);}

%%

/*** Tokens ***/
int main(void)
{   
    yylex();
    return 0;
}