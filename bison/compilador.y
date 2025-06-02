%{
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

typedef struct ast {
    int nodetype;
    struct ast *l;
    struct ast *r;
} Ast;

typedef struct numval {
    int nodetype;
    double number;
} Numval;

typedef struct varval {
    int nodetype;
    int var;
} Varval;

typedef struct flow {
    int nodetype;
    Ast *cond;
    Ast *tl;
    Ast *el;
} Flow;

typedef struct symasgn {
    int nodetype;
    int s;
    Ast *v;
} Symasgn;

typedef struct {
    int type; // 0 = número, 1 = string
    union {
        float num;
        char *str;
    } value;
} Variable;

Variable var[26];
int aux;

Ast *newast(int nodetype, Ast *l, Ast *r);
Ast *newnum(double d);
Ast *newflow(int nodetype, Ast *cond, Ast *tl, Ast *el);
Ast *newcmp(int cmptype, Ast *l, Ast *r);
Ast *newasgn(int s, Ast *v);
Ast *newValorVal(int s);
double eval(Ast *a);

int yylex();
void yyerror(char *s) {
    printf("Erro: %s\n", s);
}
%}

%union {
    char* str;
    float flo;
    int fn;
    int inte;
    Ast *a;
}

%token <flo> NUM
%token <inte> VAR
%token <str> STRING
%token INICIO FIM ESCREVA LEIA PRINT IF ELSE WHILE
%token <fn> CMP

%type <a> exp list stmt prog

%right '='
%left '+' '-'
%left '*' '/'
%nonassoc IFX NEG

%%

prog: INICIO cod FIM;

cod: stmt              { eval($1); }
   | cod stmt          { eval($2); }
   ;

stmt: IF '(' exp ')' '{' list '}' %prec IFX
        { $$ = newflow('I', $3, $6, NULL); }
    | IF '(' exp ')' '{' list '}' ELSE '{' list '}'
        { $$ = newflow('I', $3, $6, $10); }
    | WHILE '(' exp ')' '{' list '}'
        { $$ = newflow('W', $3, $6, NULL); }
    | VAR '=' exp
        { $$ = newasgn($1, $3); }
    | PRINT '(' exp ')'
        { $$ = newast('P', $3, NULL); }
    | ESCREVA '(' saidas ')'
        { $$ = NULL; }
    | LEIA '(' VAR ')'
        {
            printf("Valor de '%c': ", $3 + 'a');
            scanf("%f", &var[$3].value.num);
            var[$3].type = 0;
            $$ = NULL;
        }
    | VAR '=' STRING
        {
            var[$1].type = 1;
            var[$1].value.str = strdup($3);
            free($3);
            $$ = NULL;
        }
    ;

list: stmt             { $$ = $1; }
    | list stmt        { $$ = newast('L', $1, $2); }
    ;

saidas:
      STRING ',' saidas {
          printf("%s, ", $1); free($1);
      }
    | exp ',' saidas {
          printf("%.2f, ", eval($1));
      }
    | STRING {
          printf("%s", $1); free($1);
      }
    | exp {
          printf("%.2f", eval($1));
      }
    | VAR {
          if (var[$1].type == 0)
              printf("%.2f", var[$1].value.num);
          else
              printf("%s", var[$1].value.str);
      }
    ;

exp: exp '+' exp     { $$ = newast('+', $1, $3); }
    | exp '-' exp    { $$ = newast('-', $1, $3); }
    | exp '*' exp    { $$ = newast('*', $1, $3); }
    | exp '/' exp    { $$ = newast('/', $1, $3); }
    | '(' exp ')'    { $$ = $2; }
    | '-' exp %prec NEG { $$ = newast('M', $2, NULL); }
    | NUM            { $$ = newnum($1); }
    | VAR            { $$ = newValorVal($1); }
    ;

%%

#include "lex.yy.c"

int main() {
    yyin = fopen("entrada.txt", "r");
    if (!yyin) {
        perror("entrada.txt");
        return 1;
    }
    yyparse();
    fclose(yyin);
    return 0;
}
