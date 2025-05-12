%{
#include <stdio.h>
#include <math.h>
 
float var[26];

int yylex();
void yyerror (char *s){
	printf("%s\n", s);
}

%}

%union {
    char* str;
}

%union{
	float flo;
	int inte;
}

%token <flo> NUM 
%token <inte> VAR
%token INICIO
%token FIM
%token ESCREVA
%token LEIA
%token <str> STRING
%left '+' '-'
%left '*' '/'
%right '^'
%right NEG

%type <flo> exp
%type <flo> valor

%%

prog: INICIO cod FIM;

cod: cod cmdos |;
cmdos:
    ESCREVA '(' saidas ')'
  | LEIA '(' VAR ')' {
        printf("Valor de '%c': ", $3 + 'a');
        scanf("%f", &var[$3]);
    }
  | VAR '=' exp {
        var[$1] = $3;
	} ; 

str:  STRING { printf("%s\n", $1); free($1); };

saidas: str "," saidas |
 exp "," saidas { printf("%2.f\n", $1); } 
 |  str 
 | exp {printf("Número: %2.f\n", $1);} ;

exp: exp '+' exp {$$ = $1 + $3;}
	|exp '-' exp {$$ = $1 - $3;}
	|exp '*' exp {$$ = $1 * $3;}
	|exp '/' exp {$$ = $1 / $3;}
	|'(' exp ')' {$$ = $2;}
	|exp '^' exp {$$ = pow($1,$3);}
	|'-' exp %prec NEG {$$ = -$2;}
	|valor {$$ = $1;}
	|VAR {$$ = var[$1];}
	;

valor: NUM {$$ = $1;}
	;

%%

#include "lex.yy.c"

int main(){
	yyin=fopen("entrada.txt","r");
	yyparse();
	yylex();
	fclose(yyin);
return 0;
}
