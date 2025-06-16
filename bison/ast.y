%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h> 

#define MAX_ARRAY_SIZE 100

/*O nodetype serve para indicar o tipo de nó que está na árvore. Isso serve para a função eval() entender o que realizar naquele nó*/
 
typedef struct ast { /*Estrutura de um nó*/
	int nodetype;
	struct ast *l; /*Esquerda*/
	struct ast *r; /*Direita*/
}Ast; 

typedef struct numval { /*Estrutura de um número*/
	int nodetype;
	double number;
}Numval;

typedef struct strval {
	int nodetype;
	char* string;
}Strval;

typedef struct varval { /*Estrutura de um nome de variável, nesse exemplo uma variável é um número no vetor var[26]*/
	int nodetype;
	int var;
}Varval;

typedef struct arrayval {
	int nodetype;
	int var;        // qual array (a, b, c, etc.)
	Ast *index;     // expressão do índice
}Arrayval;

typedef struct arrayasgn {
	int nodetype;
	int var;        // qual array
	Ast *index;     // expressão do índice
	Ast *value;     // valor a ser atribuído
}Arrayasgn;

typedef struct flow {
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

double var[26][MAX_ARRAY_SIZE];     // var[variável][índice]
char* str_var[26][MAX_ARRAY_SIZE];  // str_var[variável][índice]

int array_sizes[26];  // tamanho atual de cada array
int aux;

Ast * newstr(char* s) {
	Strval *a = (Strval*) malloc(sizeof(Strval));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'S';  // 'S' para string
	a->string = strdup(s);  // duplica a string
	return (Ast*)a;
}

Ast * newarrayval(int var, Ast *index) {
	Arrayval *a = (Arrayval*) malloc(sizeof(Arrayval));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'A';  // 'A' para array access
	a->var = var;
	a->index = index;
	return (Ast*)a;
}

// NOVA FUNÇÃO PARA CRIAR NÓ DE ATRIBUIÇÃO EM ARRAY
Ast * newarrayasgn(int var, Ast *index, Ast *value) {
	Arrayasgn *a = (Arrayasgn*) malloc(sizeof(Arrayasgn));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'R';  // 'R' para array assignment
	a->var = var;
	a->index = index;
	a->value = value;
	return (Ast*)a;
}

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
		case 'N': 
			// Verifica se existe uma string armazenada nesta variável (índice 0)
			if (str_var[((Varval *)a)->var][0] != NULL) {
				printf("%s", str_var[((Varval *)a)->var][0]);
				v = 0.0;
			} else {
				v = var[((Varval *)a)->var][0]; // número (índice 0)
			}
			break;
		
		// NOVO CASO PARA ACESSO A ARRAYS
		case 'A': {
			int var_index = ((Arrayval *)a)->var;
			int array_index = (int)eval(((Arrayval *)a)->index);
			
			if (array_index < 0 || array_index >= MAX_ARRAY_SIZE) {
				printf("Erro: índice do array fora dos limites\n");
				v = 0.0;
			} else {
				// Verifica se é uma string ou número
				if (str_var[var_index][array_index] != NULL) {
					printf("%s", str_var[var_index][array_index]);
					v = 0.0;
				} else {
					v = var[var_index][array_index];
				}
			}
			break;
		}
		
		// NOVO CASO PARA ATRIBUIÇÃO EM ARRAYS
		case 'R': {
			int var_index = ((Arrayasgn *)a)->var;
			int array_index = (int)eval(((Arrayasgn *)a)->index);
			
			if (array_index < 0 || array_index >= MAX_ARRAY_SIZE) {
				printf("Erro: índice do array fora dos limites\n");
				v = 0.0;
			} else {
				if (((Arrayasgn *)a)->value->nodetype == 'S') {
					// Atribuição de string
					if (str_var[var_index][array_index]) 
						free(str_var[var_index][array_index]);
					str_var[var_index][array_index] = strdup(((Strval *)((Arrayasgn *)a)->value)->string);
					v = 0.0;
				} else {
					// Atribuição de número
					v = eval(((Arrayasgn *)a)->value);
					var[var_index][array_index] = v;
					// Limpa string se existir
					if (str_var[var_index][array_index]) {
						free(str_var[var_index][array_index]);
						str_var[var_index][array_index] = NULL;
					}
				}
				// Atualiza tamanho do array se necessário
				if (array_index >= array_sizes[var_index]) {
					array_sizes[var_index] = array_index + 1;
				}
			}
			break;
		}
		
		case '+': v = eval(a->l) + eval(a->r); break;	/*Operações "árv esq   +   árv dir"*/
		case '-': v = eval(a->l) - eval(a->r); break;	/*Operações*/
		case '*': v = eval(a->l) * eval(a->r); break;	/*Operações*/
		case '/': v = eval(a->l) / eval(a->r); break; /*Operações*/
		case '^': v =  pow(eval(a->l), eval(a->r)) ; break; /*Operações*/

		case 'S': 
			printf("%s", ((Strval *)a)->string);  // Imprime a string
			v = 0.0;  // Strings retornam 0 como valor numérico
			break;
		case 'M': v = -eval(a->l); break;				/*Operações, número negativo*/
		case '1': v = (eval(a->l) > eval(a->r))? 1 : 0; break;	/*Operações lógicas. "árv esq   >   árv dir"  Se verdade 1, falso 0*/
		case '2': v = (eval(a->l) < eval(a->r))? 1 : 0; break;
		case '3': v = (eval(a->l) != eval(a->r))? 1 : 0; break;
		case '4': v = (eval(a->l) == eval(a->r))? 1 : 0; break;
		case '5': v = (eval(a->l) >= eval(a->r))? 1 : 0; break;
		case '6': v = (eval(a->l) <= eval(a->r))? 1 : 0; break;
		
		case '=':
			if (((Symasgn *)a)->v->nodetype == 'S') {
				aux = ((Symasgn *)a)->s;
				if (str_var[aux][0]) free(str_var[aux][0]);  // libera string anterior
				str_var[aux][0] = strdup(((Strval *)((Symasgn *)a)->v)->string);
				v = 0.0;
			} else {
				v = eval(((Symasgn *)a)->v); /*Recupera o valor*/
				aux = ((Symasgn *)a)->s;	/*Recupera o símbolo/variável*/
				var[aux][0] = v;				/*Atribui à variável (índice 0)*/
			}
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
			v = 0.0;
			if( ((Flow *)a)->tl) {
				while( eval(((Flow *)a)->cond) != 0){
					v = eval(((Flow *)a)->tl);
					}
			}
		break;
			
		case 'L': eval(a->l); v = eval(a->r); break; /*Lista de operções em um bloco IF/ELSE/WHILE. Assim o analisador não se perde entre os blocos*/
		
		case 'P':
			// PRINT com suporte a arrays
			if (a->l->nodetype == 'S') {
				// String literal
				eval(a->l);  // Já imprime a string
				v = 0.0;
			} else if (a->l->nodetype == 'N') {
				// Variável - pode ser string ou número (índice 0)
				int var_index = ((Varval *)a->l)->var;
				if (str_var[var_index][0] != NULL) {
					printf("%s", str_var[var_index][0]);
				} else {
					printf("%.2f", var[var_index][0]);
				}
				v = 0.0;
			} else if (a->l->nodetype == 'A') {
				// Acesso a array
				eval(a->l);  // Já imprime o valor
				v = 0.0;
			} else {
				// Expressão numérica
				v = eval(a->l);
				printf("%.2f", v);
			}
			break;
		
		default: printf("internal error: bad node %c\n", a->nodetype);
				
	}
	return v;
}

int yylex();
void yyerror (char *s){
	printf("%s\n", s);
}

%}

%union{
	float flo;
	int fn;
	int inter;
	char* str; 
	Ast *a;
	}

%token <flo>NUM
%token <inter>VARS
%token <str>STRING    
%token FIM IF ELSE WHILE PRINT
%token <fn> CMP

%right '='
%left '+' '-'
%left '*' '/' '^'

%type <a> exp list stmt prog

%nonassoc IFX NEG

%%

val: prog FIM
	;

prog: stmt 		{eval($1);}  /*Inicia e execução da árvore de derivação*/
	| prog stmt {eval($2);}	 /*Inicia e execução da árvore de derivação*/
	;
	
/*Funções para análise sintática e criação dos nós na AST*/	
/*Verifique q nenhuma operação é realizada na ação semântica, apenas são criados nós na árvore de derivação com suas respectivas operações*/
	
stmt: IF '(' exp ')' '{' list '}' %prec IFX {$$ = newflow('I', $3, $6, NULL);}
	| IF '(' exp ')' '{' list '}' ELSE '{' list '}' {$$ = newflow('I', $3, $6, $10);}
	| WHILE '(' exp ')' '{' list '}' {$$ = newflow('W', $3, $6, NULL);}
	| VARS '=' exp {$$ = newasgn($1,$3);}
	| VARS '[' exp ']' '=' exp {$$ = newarrayasgn($1, $3, $6);}  
	| PRINT '(' exp ')' { $$ = newast('P',$3,NULL);}
	;

list:	  stmt{$$ = $1;}
		| list stmt { $$ = newast('L', $1, $2);	}
		;
	
exp: 
	 exp '+' exp {$$ = newast('+',$1,$3);}		/*Expressões matemáticas*/
	|exp '-' exp {$$ = newast('-',$1,$3);}
	|exp '*' exp {$$ = newast('*',$1,$3);}
	|exp '/' exp {$$ = newast('/',$1,$3);}
	|exp '^' exp {$$ = newast('^',$1,$3);}
	|exp CMP exp {$$ = newcmp($2,$1,$3);}		/*Testes condicionais*/
	|'(' exp ')' {$$ = $2;}
	|'-' exp %prec NEG {$$ = newast('M',$2,NULL);}
	|NUM {$$ = newnum($1);}						/*token de um número*/
	|VARS {$$ = newValorVal($1);}				/*token de uma variável*/
	|VARS '[' exp ']' {$$ = newarrayval($1, $3);}  // NOVA REGRA PARA ACESSO A ARRAYS
	|STRING {$$ = newstr($1);}    

	;

%%

#include "lex.yy.c"

int main(){
	for (int i = 0; i < 26; i++) {
		array_sizes[i] = 0;
		for (int j = 0; j < MAX_ARRAY_SIZE; j++) {
			str_var[i][j] = NULL;
			var[i][j] = 0.0;
		}
	}
	
	yyin=fopen("entrada.txt","r");
	yyparse();
	yylex();
	fclose(yyin);

	for (int i = 0; i < 26; i++) {
		for (int j = 0; j < MAX_ARRAY_SIZE; j++) {
			if (str_var[i][j]) free(str_var[i][j]);
		}
	}
	
return 0;
}

