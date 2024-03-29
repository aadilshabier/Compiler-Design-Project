%option yylineno

%{
#include "symbol_table.h"
#include "parser.hpp"
#include <fstream>
#include <iostream>

#define MAX_ID_LENGTH 31
#define PRINT_DASH for(int i=0; i<80; i++) std::cout << "-"; std::cout << "\n";
%}

flt_lit (([0-9]+[Ee][+-]?[0-9]+)|((([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*))([Ee][+-]?[0-9]+)?))

%%
"#include"[ ]*((<.*>)|(\".*\")) { return HEADER; }
"#define"[ ]+.*$ { return DEFINE; }
void|char|short|int|long|unsigned|signed|float|double|size_t { yylval.str = strdup(yytext); return DATATYPE; }
"const"|"volatile"|"static" { yylval.str = strdup(yytext); return QUALIFIER;}
"if" { return IF; }
"for" { return FOR; }
"while" { return WHILE; }
"do" { return DO; }
"continue" { return CONTINUE; }
"else" { return ELSE; }
"switch" { return SWITCH; }
"case" { return CASE; }
"default" { return DEFAULT; }
"break" { return BREAK; }
"return" { return RETURN; }
"struct" { return STRUCT; }
"union" { return UNION; }

"true"|"false" {return BOOL_CONST;}
"("|")"|"["|"]"|"{"|"}" { return yytext[0];}

"=="|"!="|"<"|"<="|">"|">="  { return COMP_OP; }
"=" { return yytext[0]; }
"+="|"-="|"*="|"/="|"%="|"&="|"|="|"^="|">>="|"<<=" { return ASSIGN_OP;}
"<<"|">>" {return SHIFT_CONST;}

"+"|"-"|"|"|"&"|"*"|"/"|"%"|","|";"|"?"|":" { return yytext[0]; } //Both Unary and Binary
"|"|"^"|"&&"|"and"|"||"|"or" { return BINARY_OP; }
"!"|"not"|"~" {return UNARY_OP;}
"++"|"--" { return INC_OP; }
"."|"->" { return MEM_OP; }

{flt_lit} { return FLOAT;}
[0-9]+ { return INTEGER;}
[a-zA-Z_][a-zA-Z0-9_]* {
    if (yyleng > MAX_ID_LENGTH) {
        std::cerr << "ERROR: Identifier " << yytext << " at line " << yylineno << " crosses maximum length of " << MAX_ID_LENGTH << std::endl;
        exit(1);
    }
    yylval.str = strdup(yytext);
    return ID;
}
[']((\\[befnrtv\\'\"\?])|.)['] { return CHAR;}

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
    return STRING;
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

[ \n\t\r] /* eat up whitespace */
<<EOF>> return END_OF_FILE;
. {
    std::cerr << "ERROR: Character not recognized: " << yytext << std::endl;
    exit(1);
}
%%

int yywrap() {
    return 1;
}
