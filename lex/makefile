all: calculadora.l
	clear
	flex -i calculadora.l
	gcc lex.yy.c -o calculadora -lfl
	./calculadora
