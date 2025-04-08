%{
    #include <stdio.h>
%}

FIM             RETURN
TYPES           (int|bool|char|float|double|void)
ATRIB           [\=|\+=|\-=|\*=|/=|]
SIMB            (\+\+|\-\-|\+|\-)
AGRUP           [\(|\)|\{|\}|\;|\,|\.|\&]
LOGICO          [>|<|>=|<=|==|!=|\&\&|\|\|]
ASPASDUPLAS     \"
CHAR            [A-Za-z_]
INTEGER         [0-9]
ALNUM           [A-Za-z0-9_]
MASK            ({ASPASDUPLAS}\%(\.{NUM}+)?[d|s|f|i]{ASPASDUPLAS})
DECIMAL         ({INTEGER}?\.{INTEGER}+)
NUM             ({INTEGER}+|{DECIMAL})
STRING          {ASPASDUPLAS}(.)*{ASPASDUPLAS}
ID              [A-Za-z_][A-Za-z0-9_]*
CONDICIONAIS    (if)|(else)|(elif)
LOOPS           (for)|(while)|(do)
BOOLEANOS       (true)|(false)
COMENTARIO       \/\/[^\n\r]*
COMENTARIO_MULTI "/*"([^*]|\*+[^*/])*\*+"/"
FUNCOES         (printf)|(scanf)
DESC            [ \n\t]
IGNORAR         [" "\t\n\r]*

%%
 /*tokens*/
{MASK}              {printf("achei uma mascara: %s\n", yytext);}
{TYPES}             {printf("achei um tipo: %s\n", yytext);}
{COMENTARIO}        {printf("achei um comentário: %s\n", yytext);}
{COMENTARIO_MULTI}  {printf("achei um comentário multi: %s\n", yytext);}
{SIMB}              {printf("achei um símbolo: %s\n", yytext);}
{FUNCOES}           {printf("achei uma função: %s\n", yytext);}
{LOOPS}             {printf("achei um loop: %s\n", yytext);}
{CONDICIONAIS}      {printf("achei um condicional: %s\n", yytext);}
{BOOLEANOS}         {printf("achei um valor booleano: %s\n", yytext);}
{STRING}            {printf("achei uma string: %s\n", yytext);}
{FIM}               {printf("achei um FIM: %s\n", yytext);}
{ID}                {printf("achei um identificador: %s\n", yytext);}
{INTEGER}           {printf("achei um número integer: %s\n", yytext);}
{DECIMAL}           {printf("achei um número decimal: %s\n", yytext);}
{NUM}               {printf("achei um número: %s\n", yytext);}
{ATRIB}             {printf("achei um atrib: %s\n", yytext);}
{AGRUP}             {printf("achei um agrupador: %s\n", yytext);}
{LOGICO}            {printf("achei um operador lógico: %s\n", yytext);}
{ASPASDUPLAS}       {printf("achei uma aspa dupla: %s\n", yytext);}




%%

/*** Tokens ***/
int main(void)
{   
    
    FILE *file = fopen("teste.c", "r");
    YY_BUFFER_STATE buffer = yy_create_buffer(file, YY_BUF_SIZE);
    yy_switch_to_buffer(buffer); // Muda o buffer para o arquivo

    yylex();
    fclose(file); // Fecha o arquivo após a análise

    yy_delete_buffer(buffer);
    return 0;
}