%{
#include <stdlib.h>
#include <string.h>
%}

DIGITO      [0-9]
LETRA       [a-zA-Z]
ID          {LETRA}
NUM         {DIGITO}+(\.{DIGITO}+)?
STRING      \"([^\"\\]|\\.)*\"

%%

[ \t\r\n]+              ;  // ignora espaços e quebras de linha

"INICIO"                { return INICIO; }
"FIM"                   { return FIM; }
"IF"                    { return IF; }
"ELSE"                  { return ELSE; }
"WHILE"                 { return WHILE; }
"printf"                { return ESCREVA; }
"scanf"                 { return LEIA; }

{ID}                    { yylval.inte = *yytext - 'a'; return VAR; }

{NUM}                   { yylval.flo = atof(yytext); return NUM; }

{STRING}                { yylval.str = strdup(yytext); return STRING; }

">" {yylval.fn = 1; return CMP; }
"<" {yylval.fn = 2; return CMP; }
"<>" {yylval.fn = 3; return CMP; }
"==" {yylval.fn = 4; return CMP; }
">=" {yylval.fn = 5; return CMP; }
"<=" {yylval.fn = 6; return CMP; }


"="                     { return '='; }
"+"                     { return '+'; }
"-"                     { return '-'; }
"*"                     { return '*'; }
"/"                     { return '/'; }
"^"                     { return '^'; }

"("                     { return '('; }
")"                     { return ')'; }
"{"                     { return '{'; }
"}"                     { return '}'; }
","                     { return ','; }
";"                     { return ';'; }

.                       { printf("Caractere inválido: %s\n", yytext); return 0; }

%%

int yywrap() { return 1; }
