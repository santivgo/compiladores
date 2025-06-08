all : ast.l ast.y
	clear
	flex -i ast.l
	bison ast.y
	gcc ast.tab.c -o analisador -lfl -lm
	./analisador
