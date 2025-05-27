%{
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h> 


typedef struct ast { /*Estrutura de um nó*/
	int nodetype;
	struct ast *l; /*Esquerda*/
	struct ast *r; /*Direita*/
}Ast; 

typedef struct numval { /*Estrutura de um número*/
	int nodetype;
	double number;
}Numval;

typedef struct varval { /*Estrutura de um nome de variável, nesse exemplo uma variável é um número no vetor var[26]*/
	int nodetype;
	int var;
}Varval;

typedef struct flow { /*Estrutura de um desvio (if/else/while)*/
	int nodetype;
	Ast *cond;		/*condição*/
	Ast *tl;		/*then, ou seja, verdade*/
	Ast *el;		/*else*/
}Flow;

typedef struct symasgn { /*Estrutura para um nó de atribuição. Para atrubuir o valor de v em s*/
	int nodetype;
	int s;
	Ast *v;
}Symasgn;


typedef struct {
    int type; // 0 = número, 1 = string
    union {
        float num;
        char *str;
    } value;
} Variable;

Variable var[26];

int aux;

Ast * newast(int nodetype, Ast *l, Ast *r){ /*Função para criar um nó*/

	Ast *a = (Ast*) malloc(sizeof(Ast));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = nodetype;
	a->l = l;
	a->r = r;
	return a;
}
 
Ast * newnum(double d) {			/*Função de que cria um número (folha)*/
	Numval *a = (Numval*) malloc(sizeof(Numval));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'K';
	a->number = d;
	return (Ast*)a;
}

Ast * newflow(int nodetype, Ast *cond, Ast *tl, Ast *el){ /*Função que cria um nó de if/else/while*/
	Flow *a = (Flow*)malloc(sizeof(Flow));
	if(!a) {
		printf("out of space");
	exit(0);
	}
	a->nodetype = nodetype;
	a->cond = cond;
	a->tl = tl;
	a->el = el;
	return (Ast *)a;
}

Ast * newcmp(int cmptype, Ast *l, Ast *r){ /*Função que cria um nó para testes lógicos*/
	Ast *a = (Ast*)malloc(sizeof(Ast));
	if(!a) {
		printf("out of space");
	exit(0);
	}
	a->nodetype = '0' + cmptype; /*Para pegar o tipe de teste, definido no arquivo.l e utilizar na função eval()*/
	a->l = l;
	a->r = r;
	return a;
}

Ast * newasgn(int s, Ast *v) { /*Função para um nó de atribuição*/
	Symasgn *a = (Symasgn*)malloc(sizeof(Symasgn));
	if(!a) {
		printf("out of space");
	exit(0);
	}
	a->nodetype = '=';
	a->s = s; /*Símbolo/variável*/
	a->v = v; /*Valor*/
	return (Ast *)a;
}


Ast * newValorVal(int s) { /*Função que recupera o nome/referência de uma variável, neste caso o número*/
	
	Varval *a = (Varval*) malloc(sizeof(Varval));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'N';
	a->var = s;
	return (Ast*)a;
	
}


double eval(Ast *a) { /*Função que executa operações a partir de um nó*/
	double v; 
	if(!a) {
		printf("internal error, null eval");
		return 0.0;
	}
	switch(a->nodetype) {
		case 'K': v = ((Numval *)a)->number; break; 	/*Recupera um número*/
		case 'N': v = var[((Varval *)a)->var]; break;	/*Recupera o valor de uma variável*/
		case '+': v = eval(a->l) + eval(a->r); break;	/*Operações "árv esq   +   árv dir"*/
		case '-': v = eval(a->l) - eval(a->r); break;	/*Operações*/
		case '*': v = eval(a->l) * eval(a->r); break;	/*Operações*/
		case '/': v = eval(a->l) / eval(a->r); break; /*Operações*/
		case 'M': v = -eval(a->l); break;				/*Operações, número negativo*/
	
		case '1': v = (eval(a->l) > eval(a->r))? 1 : 0; break;	/*Operações lógicas. "árv esq   >   árv dir"  Se verdade 1, falso 0*/
		case '2': v = (eval(a->l) < eval(a->r))? 1 : 0; break;
		case '3': v = (eval(a->l) != eval(a->r))? 1 : 0; break;
		case '4': v = (eval(a->l) == eval(a->r))? 1 : 0; break;
		case '5': v = (eval(a->l) >= eval(a->r))? 1 : 0; break;
		case '6': v = (eval(a->l) <= eval(a->r))? 1 : 0; break;
		
		case '=':
			v = eval(((Symasgn *)a)->v); /*Recupera o valor*/
			aux = ((Symasgn *)a)->s;	/*Recupera o símbolo/variável*/
			var[aux] = v;				/*Atribui à variável*/
			break;
		
		case 'I':						/*CASO IF*/
			if (eval(((Flow *)a)->cond) != 0) {	/*executa a condição / teste*/
				if (((Flow *)a)->tl)		/*Se existir árvore*/
					v = eval(((Flow *)a)->tl); /*Verdade*/
				else
					v = 0.0;
			} else {
				if( ((Flow *)a)->el) {
					v = eval(((Flow *)a)->el); /*Falso*/
				} else
					v = 0.0;
				}
			break;
			
		case 'W':
			//printf ("WHILE\n");
			v = 0.0;
			if( ((Flow *)a)->tl) {
				while( eval(((Flow *)a)->cond) != 0){
					//printf ("VERDADE\n");
					v = eval(((Flow *)a)->tl);
					}
			}
		break;
			
		case 'L': eval(a->l); v = eval(a->r); break; /*Lista de operções em um bloco IF/ELSE/WHILE. Assim o analisador não se perde entre os blocos*/
		
		case 'P': 	v = eval(a->l);		/*Recupera um valor*/
					printf ("%.2f\n",v); break;  /*Função que imprime um valor*/
		
		default: printf("internal error: bad node %c\n", a->nodetype);
				
	}
	return v;
}


int yylex();
void yyerror(char *s) {
    printf("Erro: %s\n", s);
}
%}

%union {
    char* str;
	int fn
    float flo;
    int inte;
	Ast *a;

}



%token <flo> NUM 
%token <inte> VAR
%token INICIO FIM ESCREVA LEIA
%token <str> STRING



%right '='
%left '+' '-'
%left '*' '/'

%type <a> exp list stmt prog

%nonassoc IFX NEG

%%

prog: INICIO cod FIM;

cod: stmt 		{eval($1);}
	| prog stmt {eval($2);}
	;
	
str: STRING { $$ = $1; };


stmt: IF '(' exp ')' '{' list '}' %prec IFX {$$ = newflow('I', $3, $6, NULL);}
	| IF '(' exp ')' '{' list '}' ELSE '{' list '}' {$$ = newflow('I', $3, $6, $10);}
	| WHILE '(' exp ')' '{' list '}' {$$ = newflow('W', $3, $6, NULL);}
	| VARS '=' exp {$$ = newasgn($1,$3);}
	| PRINT '(' exp ')' { $$ = newast('P',$3,NULL);} 
	| ESCREVA '(' saidas ')'   { ; }
  	| LEIA '(' VAR ')'         {
        printf("Valor de '%c': ", $3 + 'a');
        scanf("%f", &var[$3].value.num);
        var[$3].type = 0;
    }
  | VAR '=' STRING           {
        var[$1].type = 1;
        var[$1].value.str = strdup($3);
        free($3);
    };
	;

list:	  stmt{$$ = $1;}
		| list stmt { $$ = newast('L', $1, $2);	}
		;


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