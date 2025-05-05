%{
#include <stdio.h>
 
int yylex();
void yyerror (char *s){
	printf("%s\n", s);
}

%}

%token INTEGER
%token FIM
%token INICIO
%left '+' '-'
%left '*'

%%

val: INICIO cod FIM

cod: exp cod {
		printf ("Resultado: %d \n",$1);
	}
	| exp {
		printf ("Resultado: %d \n",$1);
	}
	;

exp: exp '+' exp {$$ = $1 + $3; printf ("%d + %d = %d\n",$1,$3,$$);}
	|exp '-' exp {$$ = $1 - $3; printf ("%d - %d = %d\n",$1,$3,$$);}
	|exp '*' exp {$$ = $1 * $3; printf ("%d * %d = %d\n",$1,$3,$$);}
	|valor {$$ = $1;}
	;

valor: INTEGER {$$ = $1;}
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
