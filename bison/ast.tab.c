/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 1 "ast.y"

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


#line 688 "ast.tab.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif


/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    NUM = 258,                     /* NUM  */
    VARS = 259,                    /* VARS  */
    STRING = 260,                  /* STRING  */
    FIM = 261,                     /* FIM  */
    IF = 262,                      /* IF  */
    ELSE = 263,                    /* ELSE  */
    WHILE = 264,                   /* WHILE  */
    PRINT = 265,                   /* PRINT  */
    SCAN = 266,                    /* SCAN  */
    CMP = 267,                     /* CMP  */
    IFX = 268,                     /* IFX  */
    NEG = 269                      /* NEG  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 618 "ast.y"

	float flo;
	int fn;
	char* str; 
	Ast *a;
	Ast **array_ptr;  // Para lista de elementos de array

	

#line 759 "ast.tab.c"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);



/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_NUM = 3,                        /* NUM  */
  YYSYMBOL_VARS = 4,                       /* VARS  */
  YYSYMBOL_STRING = 5,                     /* STRING  */
  YYSYMBOL_FIM = 6,                        /* FIM  */
  YYSYMBOL_IF = 7,                         /* IF  */
  YYSYMBOL_ELSE = 8,                       /* ELSE  */
  YYSYMBOL_WHILE = 9,                      /* WHILE  */
  YYSYMBOL_PRINT = 10,                     /* PRINT  */
  YYSYMBOL_SCAN = 11,                      /* SCAN  */
  YYSYMBOL_CMP = 12,                       /* CMP  */
  YYSYMBOL_13_ = 13,                       /* '='  */
  YYSYMBOL_14_ = 14,                       /* '+'  */
  YYSYMBOL_15_ = 15,                       /* '-'  */
  YYSYMBOL_16_ = 16,                       /* '*'  */
  YYSYMBOL_17_ = 17,                       /* '/'  */
  YYSYMBOL_18_ = 18,                       /* '^'  */
  YYSYMBOL_IFX = 19,                       /* IFX  */
  YYSYMBOL_NEG = 20,                       /* NEG  */
  YYSYMBOL_21_ = 21,                       /* '('  */
  YYSYMBOL_22_ = 22,                       /* ')'  */
  YYSYMBOL_23_ = 23,                       /* '{'  */
  YYSYMBOL_24_ = 24,                       /* '}'  */
  YYSYMBOL_25_ = 25,                       /* '['  */
  YYSYMBOL_26_ = 26,                       /* ']'  */
  YYSYMBOL_27_ = 27,                       /* ','  */
  YYSYMBOL_YYACCEPT = 28,                  /* $accept  */
  YYSYMBOL_val = 29,                       /* val  */
  YYSYMBOL_prog = 30,                      /* prog  */
  YYSYMBOL_stmt = 31,                      /* stmt  */
  YYSYMBOL_array_literal = 32,             /* array_literal  */
  YYSYMBOL_array_elements = 33,            /* array_elements  */
  YYSYMBOL_list = 34,                      /* list  */
  YYSYMBOL_exp = 35                        /* exp  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  15
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   194

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  28
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  8
/* YYNRULES -- Number of rules.  */
#define YYNRULES  32
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  79

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   269


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
      21,    22,    16,    14,    27,    15,     2,    17,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    13,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    25,     2,    26,    18,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    23,     2,    24,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    19,    20
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   645,   645,   648,   649,   655,   656,   657,   658,   659,
     660,   661,   662,   663,   664,   669,   674,   686,   693,   706,
     707,   711,   712,   713,   714,   715,   716,   717,   718,   719,
     720,   721,   722
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "NUM", "VARS",
  "STRING", "FIM", "IF", "ELSE", "WHILE", "PRINT", "SCAN", "CMP", "'='",
  "'+'", "'-'", "'*'", "'/'", "'^'", "IFX", "NEG", "'('", "')'", "'{'",
  "'}'", "'['", "']'", "','", "$accept", "val", "prog", "stmt",
  "array_literal", "array_elements", "list", "exp", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-58)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-31)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     175,     3,   -13,   -11,   -10,    -4,    27,   167,   -58,    34,
      76,    76,    76,    76,    37,   -58,   -58,   -58,   -58,   111,
     -58,    76,    76,    21,   -58,   176,    18,    78,   123,   132,
     141,   -16,    76,    38,   150,   -58,    19,   176,    76,    76,
      76,    76,    76,    76,    43,    39,    48,   -58,   -58,    76,
      91,   -58,   -58,    76,   176,    36,    36,    38,    38,    38,
      76,   175,   175,    98,   -58,   176,   176,   -58,    11,    54,
      35,    52,   -58,   -58,   -58,    53,   175,    63,   -58
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       0,     0,     0,     0,     0,     0,     0,     0,     3,     0,
       0,     0,     0,     0,     0,     1,     2,     4,    29,    11,
      32,     0,     0,     0,    10,     8,    30,     0,     0,     0,
       0,     0,     0,    28,     0,    15,     0,    17,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    12,    13,     0,
       0,    27,    16,     0,    26,    21,    22,    23,    24,    25,
       0,     0,     0,     0,    31,    18,     9,    19,     0,     0,
       0,     5,    20,     7,    14,     0,     0,     0,     6
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -58,   -58,   -58,     0,   -58,   -58,   -57,    -9
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
       0,     6,     7,    67,    24,    36,    68,    25
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int8 yytable[] =
{
       8,    27,    28,    29,    30,    69,    48,    17,    11,    49,
      12,    13,    33,    34,    37,     1,     9,    14,     2,    77,
       3,     4,     5,    50,    18,    26,    20,    15,    10,    54,
      55,    56,    57,    58,    59,    71,    21,    18,    19,    20,
      63,    31,    22,    32,    65,    52,    53,    35,    38,    21,
      38,    66,    41,    42,    43,    22,    60,    74,     1,    23,
      75,     2,    61,     3,     4,     5,     0,     1,    72,    72,
       2,    62,     3,     4,     5,     0,    76,    72,    73,    18,
      26,    20,     0,     0,     0,     0,     0,    78,     0,     0,
      38,    21,    39,    40,    41,    42,    43,    22,     0,     0,
       0,     0,     0,    38,    44,    39,    40,    41,    42,    43,
      38,     0,    39,    40,    41,    42,    43,    64,     0,     0,
       0,     0,     0,   -30,    70,   -30,   -30,   -30,   -30,   -30,
       0,     0,     0,     0,     0,    38,    32,    39,    40,    41,
      42,    43,     0,     0,    38,    45,    39,    40,    41,    42,
      43,     0,     0,    38,    46,    39,    40,    41,    42,    43,
       0,     0,    38,    47,    39,    40,    41,    42,    43,     0,
       0,     1,    51,    16,     2,     0,     3,     4,     5,     1,
       0,     0,     2,     0,     3,     4,     5,     0,    38,     0,
      39,    40,    41,    42,    43
};

static const yytype_int8 yycheck[] =
{
       0,    10,    11,    12,    13,    62,    22,     7,    21,    25,
      21,    21,    21,    22,    23,     4,    13,    21,     7,    76,
       9,    10,    11,    32,     3,     4,     5,     0,    25,    38,
      39,    40,    41,    42,    43,    24,    15,     3,     4,     5,
      49,     4,    21,    25,    53,    26,    27,    26,    12,    15,
      12,    60,    16,    17,    18,    21,    13,    22,     4,    25,
       8,     7,    23,     9,    10,    11,    -1,     4,    68,    69,
       7,    23,     9,    10,    11,    -1,    23,    77,    24,     3,
       4,     5,    -1,    -1,    -1,    -1,    -1,    24,    -1,    -1,
      12,    15,    14,    15,    16,    17,    18,    21,    -1,    -1,
      -1,    -1,    -1,    12,    26,    14,    15,    16,    17,    18,
      12,    -1,    14,    15,    16,    17,    18,    26,    -1,    -1,
      -1,    -1,    -1,    12,    26,    14,    15,    16,    17,    18,
      -1,    -1,    -1,    -1,    -1,    12,    25,    14,    15,    16,
      17,    18,    -1,    -1,    12,    22,    14,    15,    16,    17,
      18,    -1,    -1,    12,    22,    14,    15,    16,    17,    18,
      -1,    -1,    12,    22,    14,    15,    16,    17,    18,    -1,
      -1,     4,    22,     6,     7,    -1,     9,    10,    11,     4,
      -1,    -1,     7,    -1,     9,    10,    11,    -1,    12,    -1,
      14,    15,    16,    17,    18
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,     4,     7,     9,    10,    11,    29,    30,    31,    13,
      25,    21,    21,    21,    21,     0,     6,    31,     3,     4,
       5,    15,    21,    25,    32,    35,     4,    35,    35,    35,
      35,     4,    25,    35,    35,    26,    33,    35,    12,    14,
      15,    16,    17,    18,    26,    22,    22,    22,    22,    25,
      35,    22,    26,    27,    35,    35,    35,    35,    35,    35,
      13,    23,    23,    35,    26,    35,    35,    31,    34,    34,
      26,    24,    31,    24,    22,     8,    23,    34,    24
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    28,    29,    30,    30,    31,    31,    31,    31,    31,
      31,    31,    31,    31,    31,    32,    32,    33,    33,    34,
      34,    35,    35,    35,    35,    35,    35,    35,    35,    35,
      35,    35,    35
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     2,     1,     2,     7,    11,     7,     3,     6,
       3,     3,     4,     4,     7,     2,     3,     1,     3,     1,
       2,     3,     3,     3,     3,     3,     3,     3,     2,     1,
       1,     4,     1
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 3: /* prog: stmt  */
#line 648 "ast.y"
                        {eval((yyvsp[0].a));}
#line 1831 "ast.tab.c"
    break;

  case 4: /* prog: prog stmt  */
#line 649 "ast.y"
                    {eval((yyvsp[0].a));}
#line 1837 "ast.tab.c"
    break;

  case 5: /* stmt: IF '(' exp ')' '{' list '}'  */
#line 655 "ast.y"
                                            {(yyval.a) = newflow('I', (yyvsp[-4].a), (yyvsp[-1].a), NULL);}
#line 1843 "ast.tab.c"
    break;

  case 6: /* stmt: IF '(' exp ')' '{' list '}' ELSE '{' list '}'  */
#line 656 "ast.y"
                                                        {(yyval.a) = newflow('I', (yyvsp[-8].a), (yyvsp[-5].a), (yyvsp[-1].a));}
#line 1849 "ast.tab.c"
    break;

  case 7: /* stmt: WHILE '(' exp ')' '{' list '}'  */
#line 657 "ast.y"
                                         {(yyval.a) = newflow('W', (yyvsp[-4].a), (yyvsp[-1].a), NULL);}
#line 1855 "ast.tab.c"
    break;

  case 8: /* stmt: VARS '=' exp  */
#line 658 "ast.y"
                       {(yyval.a) = newasgn((yyvsp[-2].str),(yyvsp[0].a));}
#line 1861 "ast.tab.c"
    break;

  case 9: /* stmt: VARS '[' exp ']' '=' exp  */
#line 659 "ast.y"
                                   {(yyval.a) = newarrayasgn((yyvsp[-5].str), (yyvsp[-3].a), (yyvsp[0].a));}
#line 1867 "ast.tab.c"
    break;

  case 10: /* stmt: VARS '=' array_literal  */
#line 660 "ast.y"
                                 {(yyval.a) = newarrayvarasgn((yyvsp[-2].str), (yyvsp[0].a));}
#line 1873 "ast.tab.c"
    break;

  case 11: /* stmt: VARS '=' VARS  */
#line 661 "ast.y"
                    {(yyval.a) = newarrayvarasgn((yyvsp[-2].str), newValorVal((yyvsp[0].str)));}
#line 1879 "ast.tab.c"
    break;

  case 12: /* stmt: PRINT '(' exp ')'  */
#line 662 "ast.y"
                            { (yyval.a) = newast('P',(yyvsp[-1].a),NULL);}
#line 1885 "ast.tab.c"
    break;

  case 13: /* stmt: SCAN '(' VARS ')'  */
#line 663 "ast.y"
                            { (yyval.a) = newscan((yyvsp[-1].str), NULL);}
#line 1891 "ast.tab.c"
    break;

  case 14: /* stmt: SCAN '(' VARS '[' exp ']' ')'  */
#line 664 "ast.y"
                                    { (yyval.a) = newscan((yyvsp[-4].str), (yyvsp[-2].a));}
#line 1897 "ast.tab.c"
    break;

  case 15: /* array_literal: '[' ']'  */
#line 669 "ast.y"
                       {
        // Array vazio
        Ast **elements = malloc(sizeof(Ast*) * 1);
        (yyval.a) = newarraylit(elements, 0);
    }
#line 1907 "ast.tab.c"
    break;

  case 16: /* array_literal: '[' array_elements ']'  */
#line 674 "ast.y"
                             {
        // Array com elementos
        // Conta quantos elementos temos
        int count = 0;
        Ast **temp = (yyvsp[-1].array_ptr);
        while (temp[count] != NULL) count++;
        
        (yyval.a) = newarraylit((yyvsp[-1].array_ptr), count);
    }
#line 1921 "ast.tab.c"
    break;

  case 17: /* array_elements: exp  */
#line 686 "ast.y"
                    {
        // Primeiro elemento
        Ast **elements = malloc(sizeof(Ast*) * (MAX_ARRAY_ELEMENTS + 1));
        elements[0] = (yyvsp[0].a);
        elements[1] = NULL;  // Marca o fim
        (yyval.array_ptr) = elements;
    }
#line 1933 "ast.tab.c"
    break;

  case 18: /* array_elements: array_elements ',' exp  */
#line 693 "ast.y"
                             {
        // Adiciona mais um elemento
        int count = 0;
        while ((yyvsp[-2].array_ptr)[count] != NULL) count++;  // Conta elementos existentes
        
        if (count < MAX_ARRAY_ELEMENTS) {
            (yyvsp[-2].array_ptr)[count] = (yyvsp[0].a);
            (yyvsp[-2].array_ptr)[count + 1] = NULL;  // Marca o fim
        }
        (yyval.array_ptr) = (yyvsp[-2].array_ptr);
    }
#line 1949 "ast.tab.c"
    break;

  case 19: /* list: stmt  */
#line 706 "ast.y"
              {(yyval.a) = (yyvsp[0].a);}
#line 1955 "ast.tab.c"
    break;

  case 20: /* list: list stmt  */
#line 707 "ast.y"
                            { (yyval.a) = newast('L', (yyvsp[-1].a), (yyvsp[0].a));	}
#line 1961 "ast.tab.c"
    break;

  case 21: /* exp: exp '+' exp  */
#line 711 "ast.y"
                     {(yyval.a) = newast('+',(yyvsp[-2].a),(yyvsp[0].a));}
#line 1967 "ast.tab.c"
    break;

  case 22: /* exp: exp '-' exp  */
#line 712 "ast.y"
                     {(yyval.a) = newast('-',(yyvsp[-2].a),(yyvsp[0].a));}
#line 1973 "ast.tab.c"
    break;

  case 23: /* exp: exp '*' exp  */
#line 713 "ast.y"
                     {(yyval.a) = newast('*',(yyvsp[-2].a),(yyvsp[0].a));}
#line 1979 "ast.tab.c"
    break;

  case 24: /* exp: exp '/' exp  */
#line 714 "ast.y"
                     {(yyval.a) = newast('/',(yyvsp[-2].a),(yyvsp[0].a));}
#line 1985 "ast.tab.c"
    break;

  case 25: /* exp: exp '^' exp  */
#line 715 "ast.y"
                     {(yyval.a) = newast('^',(yyvsp[-2].a),(yyvsp[0].a));}
#line 1991 "ast.tab.c"
    break;

  case 26: /* exp: exp CMP exp  */
#line 716 "ast.y"
                     {(yyval.a) = newcmp((yyvsp[-1].fn),(yyvsp[-2].a),(yyvsp[0].a));}
#line 1997 "ast.tab.c"
    break;

  case 27: /* exp: '(' exp ')'  */
#line 717 "ast.y"
                     {(yyval.a) = (yyvsp[-1].a);}
#line 2003 "ast.tab.c"
    break;

  case 28: /* exp: '-' exp  */
#line 718 "ast.y"
                           {(yyval.a) = newast('M',(yyvsp[0].a),NULL);}
#line 2009 "ast.tab.c"
    break;

  case 29: /* exp: NUM  */
#line 719 "ast.y"
             {(yyval.a) = newnum((yyvsp[0].flo));}
#line 2015 "ast.tab.c"
    break;

  case 30: /* exp: VARS  */
#line 720 "ast.y"
              {(yyval.a) = newValorVal((yyvsp[0].str));}
#line 2021 "ast.tab.c"
    break;

  case 31: /* exp: VARS '[' exp ']'  */
#line 721 "ast.y"
                          {(yyval.a) = newarrayval((yyvsp[-3].str), (yyvsp[-1].a));}
#line 2027 "ast.tab.c"
    break;

  case 32: /* exp: STRING  */
#line 722 "ast.y"
                {(yyval.a) = newstr((yyvsp[0].str));}
#line 2033 "ast.tab.c"
    break;


#line 2037 "ast.tab.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 726 "ast.y"


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
