%{
    #include <stdio.h>
%}
CHAR [A-Za-z]
INTEGER [0-9]
MASK \%(d|s|f|i)
TYPES (int|bool|char|float|double|void)
DECIMAL ({INTEGER}?\.{INTEGER}+)
NUM ({INTEGER}+|{DECIMAL})
ATRIB \=
SIMB (\+\+|\-\-|\+=|\-=|\*=|/=|\+|\-)
AGRUP [\(|\)|\{|\}|\;|\,|\.|\&]
LOGICO [>|<|>=|<=|==|!=|\&\&|\|\|]
ASPASDUPLAS \"
STRING {ASPASDUPLAS}(.)*{ASPASDUPLAS}
CONDICIONAIS (if|else|elif)
LOOPS (for|while|do)
BOOLEANOS (true|false)
COMENTARIOS \/\/[^\n\r]*
FUNCOES (printf|scanf)


DESC [ \n\t]

%%
 /*tokens*/
{INTEGER} {printf("achei um número integer: %s\n", yytext);}
{DECIMAL} {printf("achei um número decimal: %s\n", yytext);}
{NUM} {printf("achei um número: %s\n", yytext);}
{ATRIB} {printf("achei um atrb: %s\n", yytext);}
{SIMB} {printf("achei um símbolo: %s\n", yytext);}
{DESC} {printf("achei uma simbolo desconhecido: %s\n", yytext);}

%%

/*** Tokens ***/
int main(void)
{   
    yylex();
    return 0;
}