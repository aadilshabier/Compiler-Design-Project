%option c++
%option yylineno

%{
#include <fstream>
#include "symbol_table.h"

#define MAX_ID_LENGTH 31
#define PRINT_DASH for(int i=0; i<80; i++) std::cout << "-"; std::cout << "\n";

SymbolTable symbol_table;
%}

flt_lit [+-]?(([0-9]+[Ee][+-]?[0-9]+)|((([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*))([Ee][+-]?[0-9]+)?))

%%
"#include"[ ]*((<.*>)|(\".*\")) {yyout << "HEADER:\t\t" << yytext << std::endl;}
"#define"[ ]+.*$ { yyout << "DEFINE:\t\t" << yytext << std::endl; }
void|char|short|int|long|unsigned|signed|float|double {yyout << "TYPE:\t\t" << yytext << std::endl;}
"const" {yyout << "QUALIFIER:\t" << yytext << std::endl;}
"if" {yyout << "IF" << std::endl;}
"for" {yyout << "FOR" << std::endl;}
"while" {yyout << "WHILE" << std::endl;}
"continue" {yyout << "CONTINUE" << std::endl;}
"else" {yyout << "ELSE" << std::endl;}
"switch" {yyout << "SWITCH" << std::endl;}
"case" {yyout << "CASE" << std::endl;}
"break" {yyout << "BREAK" << std::endl;}
"return" {yyout << "RETURN" << std::endl;}

"&&"|"and" {yyout << "AND" << std::endl;}
"||"|"or" {yyout << "OR" << std::endl;}
"!"|"not" {yyout << "NOT" << std::endl;}

"=="|"!="|"<"|"<="|">"|">="|"|="|"&="|"^="  {yyout << "COMP:\t\t" << yytext << std::endl; }
"+="|"-="|"*="|"/=" {yyout << "SELFOP:\t\t" << yytext << std::endl;}
"("|")"|"["|"]"|"{"|"}" {yyout << "PAREN:\t\t" << yytext << std::endl;}
";"|"="|","|"."|"+"|"-"|"*"|"/"|"|"|"&"|"^"|"~" {yyout << "OP:\t\t" << yytext << std::endl;
 }

{flt_lit} {yyout << "FLOAT:\t\t" << yytext << std::endl;}
[+|-]?[0-9]+ {yyout << "INTEGER:\t" << yytext << std::endl;}
[a-zA-Z_][a-zA-Z0-9_]* {
    if (yyleng > MAX_ID_LENGTH) {
        std::cerr << "ERROR: Identifier " << yytext << " at line " << yylineno << " crosses maximum length of " << MAX_ID_LENGTH << std::endl;
        exit(1);
    } else {
        yyout << "ID:\t\t" << yytext << std::endl;
        auto &sym = symbol_table[yytext];
        sym.linenos.push_back(yylineno);
    }
}
[']((\\[befnrtv\\'\"\?])|.)['] {yyout << "CHAR:\t\t" << yytext << std::endl;}

[\"] {
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
            std::cerr << "ERROR: String literal not closed at line " << lineno-1 << std::endl;
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
    yyout << "STRING:\t\t" << str_literal << std::endl;
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
    PRINT_DASH
    
	yyFlexLexer lexer(yyin, std::cout);
	while (lexer.yylex() != 0)
		;

	std::cout<<std::endl;
    PRINT_DASH
    std::cout << "\t\t\t\t\tSYMBOL TABLE\n";
    PRINT_DASH
	for (auto &[name, sym] : symbol_table) {
		std::cout << "NAME: " << name;
		std::cout << "  --  Lines: ";
        for (auto line : sym.linenos) {
            std::cout << line << " ";
        }
		std::cout << "  --  TYPE: " << sym.type;
		std::cout << "  --  SCOPE: " << sym.scopeno;
		std::cout << "  --  SIZE: " << sym.size;
		std::cout << "  --  ADDR: " << sym.addr;
		std::cout << "  --  VALUE: " << sym.value;
		std::cout << std::endl;
	}
    PRINT_DASH; std::cout<<std::endl;
	return 0;
}
