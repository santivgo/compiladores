%{
#include <stdio.h>
#include <math.h>
#include <string.h> // ADICIONADO

typedef struct {
    int type; // 0 = número, 1 = string
    union {
        float num;
        char *str;
    } value;
} Variable;

Variable var[26];

int yylex();
void yyerror(char *s) {
    printf("Erro: %s\n", s);
}
%}

%union {
    char* str;
    float flo;
    int inte;
}

%token <flo> NUM 
%token <inte> VAR
%token INICIO FIM ESCREVA LEIA
%token <str> STRING
%left '+' '-'
%left '*' '/'
%right '^'
%right NEG

%type <flo> exp valor
%type <str> str

%%

prog: INICIO cod FIM;

cod: cod cmdos | ;

cmdos:
    ESCREVA '(' saidas ')'   { ; }
  | LEIA '(' VAR ')'         {
        printf("Valor de '%c': ", $3 + 'a');
        scanf("%f", &var[$3].value.num);
        var[$3].type = 0;
    }
  | VAR '=' exp              {
        var[$1].type = 0;
        var[$1].value.num = $3;
    }
  | VAR '=' STRING           {
        var[$1].type = 1;
        var[$1].value.str = strdup($3);
        free($3);
    }
  ;

str: STRING { $$ = $1; };

saidas:
    STRING ',' saidas { 
        printf("%s, ", $1); 
        free($1);
    }
  | exp ',' saidas    { printf("%.2f, ", $1); }
  | STRING            { printf("%s", $1); free($1); }
  | exp               { printf("%.2f", $1); }
  | VAR               {
        if (var[$1].type == 0)
            printf("%.2f\n", var[$1].value.num);
        else
            printf("%s\n", var[$1].value.str);
    }
  ;

exp: exp '+' exp     { $$ = $1 + $3; }
    | exp '-' exp    { $$ = $1 - $3; }
    | exp '*' exp    { $$ = $1 * $3; }
    | exp '/' exp    { $$ = $1 / $3; }
    | '(' exp ')'    { $$ = $2; }
    | exp '^' exp    { $$ = pow($1, $3); }
    | '-' exp %prec NEG { $$ = -$2; }
    | valor          { $$ = $1; }
    | VAR            { 
        if (var[$1].type == 0) 
            $$ = var[$1].value.num; 
        else 
            yyerror("Variável não é numérica!");
        }
    ;

valor: NUM { $$ = $1; };

%%

#include "lex.yy.c"

int main() {
    yyin = fopen("entrada.txt", "r");
    yyparse();
    fclose(yyin);
    return 0;
}