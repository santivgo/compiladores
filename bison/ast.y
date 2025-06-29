%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h> 

#define MAX_ARRAY_SIZE 100
#define MAX_ARRAY_ELEMENTS 50  // Máximo de elementos em uma declaração de array


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

typedef struct arraylit {
    int nodetype;
    Ast **elements;     // Array de ponteiros para elementos
    int count;          // Número de elementos
}Arraylit;

typedef struct arrayvarasgn {
    int nodetype;
    int var;            // Variável que recebe o array
    Ast *array_expr;    // Expressão do array (pode ser array literal ou outra variável)
}Arrayvarasgn;

typedef struct scanval {
    int nodetype;
    int var;        // variável simples
    Ast *index;     // NULL para variável simples, expressão para array
}Scanval;

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

typedef struct printargs {
    int nodetype;
    Ast **args;     // Array de argumentos
    int count;      // Número de argumentos
}Printargs;

// ARRAYS PARA VARIÁVEIS NUMÉRICAS E STRINGS (AGORA SÃO BIDIMENSIONAIS)
double var[26][MAX_ARRAY_SIZE];     // var[variável][índice]
char* str_var[26][MAX_ARRAY_SIZE];  // str_var[variável][índice]
int array_sizes[26];  // tamanho atual de cada array
int aux;

Ast * newarraylit(Ast **elements, int count) {
    Arraylit *a = (Arraylit*) malloc(sizeof(Arraylit));
    if(!a) {
        printf("out of space");
        exit(0);
    }
    a->nodetype = 'T';  // 'T' para array liTeral
    a->elements = elements;
    a->count = count;
    return (Ast*)a;
}

Ast * newarrayvarasgn(int var, Ast *array_expr) {
    Arrayvarasgn *a = (Arrayvarasgn*) malloc(sizeof(Arrayvarasgn));
    if(!a) {
        printf("out of space");
        exit(0);
    }
    a->nodetype = 'V';  // 'V' para array Variable assignment
    a->var = var;
    a->array_expr = array_expr;
    return (Ast*)a;
}

void clear_array(int var_index) {
    for (int i = 0; i < array_sizes[var_index]; i++) {
        var[var_index][i] = 0.0;
        if (str_var[var_index][i]) {
            free(str_var[var_index][i]);
            str_var[var_index][i] = NULL;
        }
    }
    array_sizes[var_index] = 0;
}


// Criação de Nós
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

Ast * newscan(int var, Ast *index) {
    Scanval *a = (Scanval*) malloc(sizeof(Scanval));
    if(!a) {
        printf("out of space");
        exit(0);
    }
    a->nodetype = 'D';  // 'D' para read
    a->var = var;
    a->index = index;   // NULL para variável simples
    return (Ast*)a;
}


// NOVA FUNÇÃO PARA CRIAR NÓ DE ACESSO A ARRAY
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

Ast * newprintargs(Ast **args, int count) {
    Printargs *a = (Printargs*) malloc(sizeof(Printargs));
    if(!a) {
        printf("out of space");
        exit(0);
    }
    a->nodetype = 'Q';  // 'Q' para print com múltiplos argumentos
    a->args = args;
    a->count = count;
    return (Ast*)a;
}

char* read_string() {
    char* buffer = malloc(1000);  // Buffer temporário
    if (fgets(buffer, 1000, stdin)) {
        // Remove newline se existir
        int len = strlen(buffer);
        if (len > 0 && buffer[len-1] == '\n') {
            buffer[len-1] = '\0';
        }
        // Redimensiona para o tamanho exato
        char* result = malloc(strlen(buffer) + 1);
        strcpy(result, buffer);
        free(buffer);
        return result;
    }
    free(buffer);
    return strdup("");  // Retorna string vazia em caso de erro
}

int is_number(const char* str) {
    if (!str || !*str) return 0;
    
    char* endptr;
    strtod(str, &endptr);
    
    // Se endptr aponta para o final da string, é um número válido
    return (*endptr == '\0');
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
				// Apenas retorna o valor, não imprime
				if (str_var[var_index][array_index] != NULL) {
					v = 0.0; // Ou algum código especial para indicar que é string
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
		case 'D': {
            int var_index = ((Scanval *)a)->var;
            char input_buffer[1000];
            
            if (((Scanval *)a)->index == NULL) {
                fflush(stdout);
                
                if (fgets(input_buffer, sizeof(input_buffer), stdin)) {
                    // Remove newline
                    int len = strlen(input_buffer);
                    if (len > 0 && input_buffer[len-1] == '\n') {
                        input_buffer[len-1] = '\0';
                    }
                    
                    if (is_number(input_buffer)) {
                        // É um número
                        v = atof(input_buffer);
                        var[var_index][0] = v;
                        // Limpa string se existir
                        if (str_var[var_index][0]) {
                            free(str_var[var_index][0]);
                            str_var[var_index][0] = NULL;
                        }
                    } else {
                        // É uma string
                        if (str_var[var_index][0]) {
                            free(str_var[var_index][0]);
                        }
                        str_var[var_index][0] = strdup(input_buffer);
                        var[var_index][0] = 0.0;  // Zera valor numérico
                        v = 0.0;
                    }
                }
            } else {
                // Leitura para array
                int array_index = (int)eval(((Scanval *)a)->index);
                
                if (array_index < 0 || array_index >= MAX_ARRAY_SIZE) {
                    printf("Erro: índice do array fora dos limites\n");
                    v = 0.0;
                } else {
                    fflush(stdout);
                    
                    if (fgets(input_buffer, sizeof(input_buffer), stdin)) {
                        // Remove newline
                        int len = strlen(input_buffer);
                        if (len > 0 && input_buffer[len-1] == '\n') {
                            input_buffer[len-1] = '\0';
                        }
                        
                        if (is_number(input_buffer)) {
                            // É um número
                            v = atof(input_buffer);
                            var[var_index][array_index] = v;
                            // Limpa string se existir
                            if (str_var[var_index][array_index]) {
                                free(str_var[var_index][array_index]);
                                str_var[var_index][array_index] = NULL;
                            }
                        } else {
                            // É uma string
                            if (str_var[var_index][array_index]) {
                                free(str_var[var_index][array_index]);
                            }
                            str_var[var_index][array_index] = strdup(input_buffer);
                            var[var_index][array_index] = 0.0;
                            v = 0.0;
                        }
                        
                        // Atualiza tamanho do array se necessário
                        if (array_index >= array_sizes[var_index]) {
                            array_sizes[var_index] = array_index + 1;
                        }
                    }
                }
            }
            break;
        }
		case 'T': {
            // Array literal - apenas retorna 0 (será usado em atribuições)
            v = 0.0;
            break;
        }
        
        // NOVO CASO PARA ATRIBUIÇÃO DE ARRAY COMPLETO
        case 'V': {
            int var_index = ((Arrayvarasgn *)a)->var;
            Ast *array_expr = ((Arrayvarasgn *)a)->array_expr;
            
            // Limpa o array atual
            clear_array(var_index);
            
            if (array_expr->nodetype == 'T') {
                // Array literal [1, 2, 3] ou []
                Arraylit *lit = (Arraylit *)array_expr;
                
                // Copia os elementos
                for (int i = 0; i < lit->count && i < MAX_ARRAY_SIZE; i++) {
                    if (lit->elements[i]->nodetype == 'S') {
                        // Elemento é string
                        str_var[var_index][i] = strdup(((Strval *)lit->elements[i])->string);
                        var[var_index][i] = 0.0;
                    } else {
                        // Elemento é número
                        var[var_index][i] = eval(lit->elements[i]);
                        str_var[var_index][i] = NULL;
                    }
                }
                array_sizes[var_index] = lit->count;
                
            } else if (array_expr->nodetype == 'N') {
                // Cópia de outro array: b = a
                int src_var = ((Varval *)array_expr)->var;
                
                // Copia todos os elementos do array origem
                for (int i = 0; i < array_sizes[src_var] && i < MAX_ARRAY_SIZE; i++) {
                    if (str_var[src_var][i] != NULL) {
                        str_var[var_index][i] = strdup(str_var[src_var][i]);
                        var[var_index][i] = 0.0;
                    } else {
                        var[var_index][i] = var[src_var][i];
                        str_var[var_index][i] = NULL;
                    }
                }
                array_sizes[var_index] = array_sizes[src_var];
            }
            
            v = 0.0;
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
		case '7': v = (eval(a->l) != 0 && eval(a->r) != 0) ? 1 : 0; break; // &&
		case '8': v = (eval(a->l) != 0 || eval(a->r) != 0) ? 1 : 0; break; // ||
		case '!': v = (eval(a->l) == 0) ? 1 : 0; break; 
	
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
			if (a->l->nodetype == 'A') {
				// Acesso a array - trata string ou número
				int var_index = ((Arrayval *)a->l)->var;
				int array_index = (int)eval(((Arrayval *)a->l)->index);
				
				if (str_var[var_index][array_index] != NULL) {
					printf("%s", str_var[var_index][array_index]);
				} else {
					printf("%.2f", var[var_index][array_index]);
				}
				v = 0.0;  // ✅ Adicione esta linha
			} else {
				v = eval(a->l);  // Avalia qualquer expressão
				if (a->l->nodetype == 'S') {
					// String já foi impressa no eval
				} else {
					printf("%.2f", v);  // Imprime o resultado numérico
				}
			}
			break;  // ✅ Um só break para todo o case 'P'
		case 'Q': {
			// Print com múltiplos argumentos
			Printargs *print_node = (Printargs *)a;
			
			// Conta quantos argumentos temos
			int count = 0;
			while (print_node->args[count] != NULL) count++;
			
			// Imprime cada argumento
			for (int i = 0; i < count; i++) {
				Ast *arg = print_node->args[i];
				
				if (arg->nodetype == 'S') {
					// É uma string - apenas avalia (já imprime)
					eval(arg);
				} else if (arg->nodetype == 'A') {
					// Acesso a array
					int var_index = ((Arrayval *)arg)->var;
					int array_index = (int)eval(((Arrayval *)arg)->index);
					
					if (array_index >= 0 && array_index < MAX_ARRAY_SIZE) {
						if (str_var[var_index][array_index] != NULL) {
							printf("%s", str_var[var_index][array_index]);
						} else {
							printf("%.2f", var[var_index][array_index]);
						}
					}
				} else if (arg->nodetype == 'N') {
					// Variável simples
					int var_index = ((Varval *)arg)->var;
					if (str_var[var_index][0] != NULL) {
						printf("%s", str_var[var_index][0]);
					} else {
						printf("%.2f", var[var_index][0]);
					}
				} else {
					// Expressão numérica
					double result = eval(arg);
					printf("%.2f", result);
				}
			}
			
			v = 0.0;
			break;
		}

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
	Ast **array_ptr;  // Para lista de elementos de array
    Ast **print_args; // NOVO: Para argumentos do print

	}

%token <flo>NUM
%token <inter>VARS
%token <fn> LOGICAL NOT
%token <str>STRING    
%token FIM IF ELSE WHILE PRINT SCAN
%token <fn> CMP

%left LOGICAL        
%right NOT          
%right '='
%left '+' '-'
%left '*' '/' '^'

%type <a> exp list stmt prog array_literal
%type <array_ptr> array_elements
%type <print_args> print_arguments 



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
	| VARS '=' array_literal {$$ = newarrayvarasgn($1, $3);}     // NOVA REGRA: b = [1,2,3]
    | VARS '=' VARS {$$ = newarrayvarasgn($1, newValorVal($3));} // NOVA REGRA: b = a (cópia de array)
    | PRINT '(' print_arguments ')' { $$ = newprintargs($3, -1);} // MODIFICADO
	| SCAN '(' VARS ')' { $$ = newscan($3, NULL);}              // SCAN(variável)
    | SCAN '(' VARS '[' exp ']' ')' { $$ = newscan($3, $5);}    // SCAN(array[índice])
	;


// NOVA REGRA PARA ARRAY LITERAL
array_literal: '[' ']' {
        // Array vazio
        Ast **elements = malloc(sizeof(Ast*) * 1);
        $$ = newarraylit(elements, 0);
    }
    | '[' array_elements ']' {
        // Array com elementos
        // Conta quantos elementos temos
        int count = 0;
        Ast **temp = $2;
        while (temp[count] != NULL) count++;
        
        $$ = newarraylit($2, count);
    }
    ;

// NOVA REGRA PARA LISTA DE ELEMENTOS
array_elements: exp {
        // Primeiro elemento
        Ast **elements = malloc(sizeof(Ast*) * (MAX_ARRAY_ELEMENTS + 1));
        elements[0] = $1;
        elements[1] = NULL;  // Marca o fim
        $$ = elements;
    }
    | array_elements ',' exp {
        // Adiciona mais um elemento
        int count = 0;
        while ($1[count] != NULL) count++;  // Conta elementos existentes
        
        if (count < MAX_ARRAY_ELEMENTS) {
            $1[count] = $3;
            $1[count + 1] = NULL;  // Marca o fim
        }
        $$ = $1;
    }
    ;

list:	  stmt{$$ = $1;}
		| list stmt { $$ = newast('L', $1, $2);	}
		;

print_arguments: exp {
        // Primeiro argumento
        Ast **args = malloc(sizeof(Ast*) * (MAX_ARRAY_ELEMENTS + 1));
        args[0] = $1;
        args[1] = NULL;  // Marca o fim
        $$ = args;
    }
    | print_arguments ',' exp {
        // Adiciona mais um argumento
        int count = 0;
        while ($1[count] != NULL) count++;  // Conta argumentos existentes
        
        if (count < MAX_ARRAY_ELEMENTS) {
            $1[count] = $3;
            $1[count + 1] = NULL;  // Marca o fim
        }
        $$ = $1;
    }
    ;
	
exp: 
	 exp '+' exp {$$ = newast('+',$1,$3);}		/*Expressões matemáticas*/
	|exp '-' exp {$$ = newast('-',$1,$3);}
	|exp '*' exp {$$ = newast('*',$1,$3);}
	|exp '/' exp {$$ = newast('/',$1,$3);}
	|exp '^' exp {$$ = newast('^',$1,$3);}
	|exp CMP exp {$$ = newcmp($2,$1,$3);}		/*Testes condicionais*/
	|exp LOGICAL exp {$$ = newcmp($2,$1,$3);}  // NOVA REGRA PARA && e ||
    |NOT exp %prec NOT {$$ = newast('!', $2, NULL);}  // NOVA REGRA PARA !
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
	// Inicializa arrays
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

	// Libera memória das strings
	for (int i = 0; i < 26; i++) {
		for (int j = 0; j < MAX_ARRAY_SIZE; j++) {
			if (str_var[i][j]) free(str_var[i][j]);
		}
	}
	
return 0;
}