%{

%}

NUM [0-9]+\.?[0-9]*
VARS[a-z]
STRING \"([^"\\]|\\.)*\"   
FIM "FIM"
IF "IF"
ELSE "ELSE"
WHILE "WHILE"
PRINT "PRINT"
SCAN "SCAN"    



%%

{VARS} {
	yylval.inter = *yytext - 'a';
	return VARS;
	}

{NUM} {
	yylval.flo = atof(yytext);
	return NUM;
	}


{STRING} {                            
	int len = strlen(yytext) - 2;       // -2 para remover aspas
	char* str = malloc(len + 1);
	strncpy(str, yytext + 1, len);      // copia sem a primeira aspa
	str[len] = '\0';
	
	// Processa caracteres de escape básicos
	char* processed = malloc(len + 1);
	int i = 0, j = 0;
	while (str[i]) {
		if (str[i] == '\\' && str[i+1]) {
			switch (str[i+1]) {
				case 'n': processed[j++] = '\n'; break;
				case 't': processed[j++] = '\t'; break;
				case 'r': processed[j++] = '\r'; break;
				case '\\': processed[j++] = '\\'; break;
				case '"': processed[j++] = '"'; break;
				default: 
					processed[j++] = str[i];
					processed[j++] = str[i+1];
			}
			i += 2;
		} else {
			processed[j++] = str[i++];
		}
	}
	processed[j] = '\0';
	
	free(str);
	yylval.str = processed;
	return STRING;
}

[-+()=/*^{};[\],] {return *yytext;} 
			

">" {yylval.fn = 1; return CMP; }
"<" {yylval.fn = 2; return CMP; }
"!=" {yylval.fn = 3; return CMP; }
"==" {yylval.fn = 4; return CMP; }
">=" {yylval.fn = 5; return CMP; }
"<=" {yylval.fn = 6; return CMP; }
"&&" {yylval.fn = 7; return LOGICAL; }
"||" {yylval.fn = 8; return LOGICAL; }
"!" {yylval.fn = 9; return NOT;}  // Adicionar valor para NOT




{FIM} {return FIM;}
{IF} {return IF;}
{ELSE} {return ELSE;}
{WHILE} {return WHILE;}
{PRINT} {return PRINT;}
{SCAN} {return SCAN;}  
[\ \n\t]*	{;}
"//".* {;}
%%