%option yylineno

%{
#include <fstream>

%}

log_and "&&"|"and"
log_or "||"|"or"
log_not "!"|"not"

%%
"#include"[ ]*((<.*>)|(\".*\")) {yyout << "HEADER: " << yytext << std::endl;}
void|char|short|int|long|unsigned|signed|float|double {yyout << "TYPE: " << yytext << std::endl;}
"const" {yyout << "QUALIFIER: " << yytext << std::endl;}
"if" {yyout << "IF" << std::endl;}
"for" {yyout << "FOR" << std::endl;}
"while" {yyout << "WHILE" << std::endl;}
"continue" {yyout << "CONTINUE" << std::endl;}
"else" {yyout << "ELSE" << std::endl;}
"switch" {yyout << "SWITCH" << std::endl;}
"case" {yyout << "CASE" << std::endl;}
"break" {yyout << "BREAK" << std::endl;}
"return" {yyout << "RETURN" << std::endl;}

log_or {yyout << "OR" << std::endl;}
log_and {yyout << "AND" << std::endl;}
log_not {yyout << "NOT" << std::endl;}
"=="|"!="|"<"|"<="|">"|">=" {yyout << "COMP: " << yytext << std::endl; /* TODO: add bitwise ops */}
"+="|"-="|"*="|"/=" {yyout << "SELFOP: " << yytext << std::endl;}
"("|")"|"["|"]"|"{"|"}" {yyout << "PAREN: " << yytext << std::endl;}
";"|"="|","|"."|"+"|"-"|"*"|"/" {yyout << "OP: " << yytext << std::endl; /* TODO: add bitwise ops */
 }

[+|-]?[0-9]+ {yyout << "INTEGER: " << yytext << std::endl;}
[+|-]?[0-9]+"."[0-9]* {yyout << "FLOAT: " << yytext << std::endl;}
[a-zA-Z_][a-zA-Z0-9_]* {yyout << "ID: " << yytext << std::endl;}

\"(\\.|[^\"])*\" {yyout << "STRING: " << yytext << std::endl;}

\/\/.*$ /* remove single line headers */
\/\*(?s:.)*\*\/ /* remove multi line headers */
[ \n\t] /* eat up whitespace */
. ;
%%

int yyFlexLexer::yywrap() {
	return 1;
}

int main(int argc, char* argv[]) {
	std::ifstream yyin("./test/prog1.c");
	yyFlexLexer lexer(yyin, std::cout);
	while (lexer.yylex() != 0)
		;
	return 0;
}
