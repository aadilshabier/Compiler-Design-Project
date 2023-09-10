%option yylineno

%{
#include <fstream>

#define MAX_ID_LENGTH 31

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
"=="|"!="|"<"|"<="|">"|">="|"|="|"&="|"^="  {yyout << "COMP: " << yytext << std::endl; }
"+="|"-="|"*="|"/=" {yyout << "SELFOP: " << yytext << std::endl;}
"("|")"|"["|"]"|"{"|"}" {yyout << "PAREN: " << yytext << std::endl;}
";"|"="|","|"."|"+"|"-"|"*"|"/"|"|"|"&"|"^"|"~" {yyout << "OP: " << yytext << std::endl;
 }

[+|-]?[0-9]+ {yyout << "INTEGER: " << yytext << std::endl;}
[+|-]?[0-9]+"."[0-9]*([Ee][+|-]?[0-9]+)? {yyout << "FLOAT: " << yytext << std::endl;}
[a-zA-Z_][a-zA-Z0-9_]* {
    if (yyleng > MAX_ID_LENGTH) {
        std::cerr << "ERROR: Indentifier " << yytext << " at line " << yylineno << " crosses maximum length of " << MAX_ID_LENGTH << std::endl;
        exit(1);
    } else {
        yyout << "ID: " << yytext << std::endl;
    }
}
"'""\\"?".""'" {yyout << "CHAR: " << yytext << std::endl;}

\"(\\.|[^\"])*\" {yyout << "STRING: " << yytext << std::endl;}

\/\/.*$ /* remove single line headers */
"/*" {
    /* remove multi line headers */
    int start_lineno = yylineno;
    int c;
    bool done = false;
    while ((c = yyinput()) != 0) {
        if(c == '*') {
            if((c = yyinput()) == '/') {
                done = true;
                break;
            }
        }
    }
    if (not done) {
       std::cerr << "ERROR: Multiline comment started at line " << start_lineno << " not terminated\n";
       exit(1);
    }
}
[ \n\t] /* eat up whitespace */
. ;
%%

int yyFlexLexer::yywrap() {
	return 1;
}

int main(int argc, char* argv[]) {
	if (argc < 2) {
		std::cerr << "ERROR: filename not given!\n";
	}
	std::ifstream yyin(argv[1]);
	if (not yyin.is_open()) {
		std::cerr << "ERROR: file with filename does not exist: " << argv[1] << std::endl;
	}
	yyFlexLexer lexer(yyin, std::cout);
	while (lexer.yylex() != 0)
		;
	return 0;
}
