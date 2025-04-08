all: compilador.l
	clear
	flex -i compilador.l
	gcc lex.yy.c -o compilador -lfl
	./compilador
