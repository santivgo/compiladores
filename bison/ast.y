%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h> 

#define MAX_ARRAY_SIZE 100
#define MAX_ARRAY_ELEMENTS 50  // Máximo de elementos em uma declaração de array
#define MAX_VARIABLES 1000  // Máximo de variáveis
#define HASH_TABLE_SIZE 101


/*O nodetype serve para indicar o tipo de nó que está na árvore. Isso serve para a função eval() entender o que realizar naquele nó*/
 
 typedef struct variable {
    char* name;                           // Nome da variável
    double values[MAX_ARRAY_SIZE];        // Valores numéricos
    char* strings[MAX_ARRAY_SIZE];        // Valores string
    int array_size;                       // Tamanho atual do array
    struct variable* next;                // Para lista ligada (caso de colisão)
} Variable;

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
	char* name;
}Varval;

typedef struct arrayval {
	int nodetype;
	char* name;        // qual array (a, b, c, etc.)
	Ast *index;     // expressão do índice
}Arrayval;

typedef struct arrayasgn {
	int nodetype;
	char* name;        // qual array
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
    char* name;           
    Ast *array_expr;    // Expressão do array (pode ser array literal ou outra variável)
}Arrayvarasgn;

typedef struct scanval {
    int nodetype;
    char* name;        // variável simples
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

Variable* variable_table[HASH_TABLE_SIZE];

unsigned int hash_function(const char* name) {
    unsigned int hash = 0;
    while (*name) {
        hash = hash * 31 + *name;
        name++;
    }
    return hash % HASH_TABLE_SIZE;
}
Variable* find_or_create_variable(const char* name) {
    unsigned int index = hash_function(name);
    Variable* var = variable_table[index];
    
    // Procura na lista ligada
    while (var != NULL) {
        if (strcmp(var->name, name) == 0) {
            return var;  // Encontrou
        }
        var = var->next;
    }
    
    // Não encontrou, cria nova variável
    Variable* new_var = (Variable*)malloc(sizeof(Variable));
    if (!new_var) {
        printf("Erro: sem memória para nova variável\n");
        exit(1);
    }
    
    new_var->name = strdup(name);
    new_var->array_size = 0;
    new_var->next = variable_table[index];
    
    // Inicializa arrays
    for (int i = 0; i < MAX_ARRAY_SIZE; i++) {
        new_var->values[i] = 0.0;
        new_var->strings[i] = NULL;
    }
    
    variable_table[index] = new_var;
    return new_var;
}

void clear_variable_array(Variable* var) {
    for (int i = 0; i < var->array_size; i++) {
        var->values[i] = 0.0;
        if (var->strings[i]) {
            free(var->strings[i]);
            var->strings[i] = NULL;
        }
    }
    var->array_size = 0;
}

// ARRAYS PARA VARIÁVEIS NUMÉRICAS E STRINGS (AGORA SÃO BIDIMENSIONAIS)
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

Ast * newarrayvarasgn(char* name, Ast *array_expr) {
    Arrayvarasgn *a = (Arrayvarasgn*) malloc(sizeof(Arrayvarasgn));
    if(!a) {
        printf("out of space");
        exit(0);
    }
    a->nodetype = 'V';  // 'V' para array Variable assignment
    a->name = strdup(name); 
    a->array_expr = array_expr;
    return (Ast*)a;
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

Ast * newscan(char* name, Ast *index) {
    Scanval *a = (Scanval*) malloc(sizeof(Scanval));
    if(!a) {
        printf("out of space");
        exit(0);
    }
    a->nodetype = 'D';  // 'D' para read
    a->name = strdup(name);
    a->index = index;   // NULL para variável simples
    return (Ast*)a;
}


// NOVA FUNÇÃO PARA CRIAR NÓ DE ACESSO A ARRAY
Ast * newarrayval(char* name, Ast *index) {
	Arrayval *a = (Arrayval*) malloc(sizeof(Arrayval));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'A';  // 'A' para array access
	a->name = strdup(name);
	a->index = index;
	return (Ast*)a;
}

// NOVA FUNÇÃO PARA CRIAR NÓ DE ATRIBUIÇÃO EM ARRAY
Ast * newarrayasgn(char* name, Ast *index, Ast *value) {
	Arrayasgn *a = (Arrayasgn*) malloc(sizeof(Arrayasgn));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'R';  // 'R' para array assignment
	a->name = strdup(name);
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

Ast * newasgn(char* name, Ast *v) { /*Função para um nó de atribuição*/
	Symasgn *a = (Symasgn*)malloc(sizeof(Symasgn));
	if(!a) {
		printf("out of space");
	exit(0);
	}
	a->nodetype = '=';
	a->name = strdup(name);  
	a->v = v; /*Valor*/
	return (Ast *)a;
}

Ast * newValorVal(char* name) { /*Função que recupera o nome/referência de uma variável, neste caso o número*/
	
	Varval *a = (Varval*) malloc(sizeof(Varval));
	if(!a) {
		printf("out of space");
		exit(0);
	}
	a->nodetype = 'N';
	a->var = strdup(name);
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
		case 'N': {
			Variable* var = find_or_create_variable(((Varval *)a)->name);
			if (var->strings[0] != NULL) {
				printf("%s", var->strings[0]);
				v = 0.0;
			} else {
				v = var->values[0];
			}
			break;
		}
		
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
            clear_variable_array(var);
            
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
	char* str; 
	Ast *a;
	Ast **array_ptr;  // Para lista de elementos de array

	}

%token <flo>NUM
%token <str>VARS
%token <str>STRING    
%token FIM IF ELSE WHILE PRINT SCAN
%token <fn> CMP

%right '='
%left '+' '-'
%left '*' '/' '^'

%type <a> exp list stmt prog array_literal
%type <array_ptr> array_elements


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
	| PRINT '(' exp ')' { $$ = newast('P',$3,NULL);}
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
	for (int i = 0; i < HASH_TABLE_SIZE; i++) {
		variable_table[i] = NULL;
	}

	
	yyin=fopen("entrada.txt","r");
	yyparse();
	yylex();
	fclose(yyin);

	// Libera memória das strings
	for (int i = 0; i < HASH_TABLE_SIZE; i++) {
		Variable* var = variable_table[i];
		while (var != NULL) {
			Variable* next = var->next;
			
			// Libera strings do array
			for (int j = 0; j < MAX_ARRAY_SIZE; j++) {
				if (var->strings[j]) free(var->strings[j]);
			}
			
			free(var->name);
			free(var);
			var = next;
		}
	}
	
	
return 0;
}