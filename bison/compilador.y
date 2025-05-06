%{
#include <stdio.h>
#include <math.h>
 
int yylex();
void yyerror (char *s){
	printf("%s\n", s);
}

%}

%token INTEGER
%token INICIO
%token FIM
%token ID
%token ATRIB MAISIGUAL MENOSIGUAL VEZESIGUAL DIVIGUAL
%left '+' '-'
%left '*' '/'
%right '^'

%%

val: INICIO cod FIM;

cod: exp cod {
		printf ("Resultado: %d \n",$1);} | atr cod
		| atr | exp {	printf ("Resultado: %d \n",$1);};


atr: ID ATRIB exp {	
	printf ("%s recebe %d\n",$1,$3);
	}

exp: exp '+' exp {$$ = $1 + $3; printf ("%d + %d = %d\n",$1,$3,$$);}
	|exp '-' exp {$$ = $1 - $3; printf ("%d - %d = %d\n",$1,$3,$$);}
	|exp '*' exp {$$ = $1 * $3; printf ("%d * %d = %d\n",$1,$3,$$);}
	|exp '/' exp {$$ = $1 / $3; printf ("%d / %d = %d\n",$1,$3,$$);}
	|exp '^' exp {$$ = (int)pow($1, $3); printf ("%d ^ %d = %d\n",$1,$3,$$);}
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
