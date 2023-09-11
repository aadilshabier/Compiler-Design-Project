%option c++
%option yylineno

%{
#include <fstream>
#include "symbol_table.h"

#define MAX_ID_LENGTH 31

SymbolTable symbol_table;
%}

flt_lit [+-]?(([0-9]+[Ee][+-]?[0-9]+)|((([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*))([Ee][+-]?[0-9]+)?))

%%
"#include"[ ]*((<.*>)|(\".*\")) {yyout << "HEADER: " << yytext << std::endl;}
"#define"[ ]+.*$ { yyout << "DEFINE: " << yytext << std::endl; }
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

"&&"|"and" {yyout << "OR" << std::endl;}
"||"|"or" {yyout << "AND" << std::endl;}
"!"|"not" {yyout << "NOT" << std::endl;}

"=="|"!="|"<"|"<="|">"|">="|"|="|"&="|"^="  {yyout << "COMP: " << yytext << std::endl; }
"+="|"-="|"*="|"/=" {yyout << "SELFOP: " << yytext << std::endl;}
"("|")"|"["|"]"|"{"|"}" {yyout << "PAREN: " << yytext << std::endl;}
";"|"="|","|"."|"+"|"-"|"*"|"/"|"|"|"&"|"^"|"~" {yyout << "OP: " << yytext << std::endl;
 }

{flt_lit} {yyout << "FLOAT: " << yytext << std::endl;}
[+|-]?[0-9]+ {yyout << "INTEGER: " << yytext << std::endl;}
[a-zA-Z_][a-zA-Z0-9_]* {
    if (yyleng > MAX_ID_LENGTH) {
        std::cerr << "ERROR: Indentifier " << yytext << " at line " << yylineno << " crosses maximum length of " << MAX_ID_LENGTH << std::endl;
        exit(1);
    } else {
        yyout << "ID: " << yytext << std::endl;
        // insert new symbol if not already found
        if (auto it = symbol_table.find(yytext); it==symbol_table.end()) {
            auto &sym = symbol_table[yytext];
            sym.lineno = yylineno;
        }
    }
}
"'""\\"?."'" {yyout << "CHAR: " << yytext << std::endl;}

"\"" {
    std::string str_literal = "\"";
    int c;
    int lineno = 0;
    while ((c=yyinput()) != 0) {
        lineno = yylineno;
        if (c == '"') {
            str_literal += c;
            break;
        }
        if (c == '\n') {
            std::cerr << "ERROR: String literal not closed at line " << lineno << std::endl;
            exit(1);
        }
        str_literal += c;
        if (c == '\\') {
            const static std::string escape = "befnrtv\\'\"?";
            int nextc = yyinput();
            if (escape.find(nextc) == escape.npos) {
                std::cerr << "ERROR: Escape sequence not recognized: \\"  << (char)nextc << " at line " << lineno << std::endl;
                exit(1);
            }
            str_literal += nextc;
        }
    }
    yyout << "STRING: " << str_literal << std::endl;
}

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
. {
    std::cerr << "Character not recognized: " << yytext << std::endl;
    exit(1);
}
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
		std::cerr << "ERROR: file does not exist: " << argv[1] << std::endl;
	}
	yyFlexLexer lexer(yyin, std::cout);
	while (lexer.yylex() != 0)
		;
	std::cout << "\nSYMBOLS:\n";
	for (auto &[name, sym] : symbol_table) {
		std::cout << "Name: " << name;
		std::cout << "  Line: " << sym.lineno;
		std::cout << "  Type: " << sym.type;
		std::cout << "  Scope: " << sym.scopeno;
		std::cout << "  Size: " << sym.size;
		std::cout << "  Addr: " << sym.addr;
		std::cout << "  Value: " << sym.value;
		std::cout << std::endl;
	}
	return 0;
}
