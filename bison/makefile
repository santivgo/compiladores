all: compilador.l
	clear
	flex -i compilador.l
	bison compilador.y
	gcc compilador.tab.c -o compilador -lfl -lm
	./compilador
