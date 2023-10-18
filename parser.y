%{
	#include <iostream>
	using namespace std;

	int yylex();
	extern "C" {
		void yyerror(const char *msg);
	}
	
%}

%token FOR IF ELSE WHILE BOOL_CONST BINARY_OP ASSIGN_OP
INTEGER FLOAT ID STRING ARITHMETIC HEADER DEFINE RETURN DATATYPE COMP_OP UNARY_OP MEM_OP SEMI COMMA QUALIFIER CONTINUE BREAK SWITCH CASE STRUCT CHAR

%start program_unit
%%
program_unit: HEADER program_unit
            | translation_unit
;

translation_unit: external_decl translation_unit
                |
;

external_decl: function_definition
             | decl
;

function_definition: decl_specs ID '(' param_list ')' compound_stat
;

decl: decl_specs init_declarator_list ';'
;

decl_specs : QUALIFIER DATATYPE
           | DATATYPE
           | QUALIFIER
           |
;

param_list: param
          | param ',' param_list
;

param: decl_specs ID
;

init_declarator_list: init_declarator
         | init_declarator ',' init_declarator_list
;

init_declarator: ID
               | ID '=' exp
;

stat: exp_stat
    | compound_stat
    | decl
    | jump_stat
;

exp_stat: exp ';'
        | ';'
;

compound_stat: '{'stat_list '}'
;

stat_list: stat stat_list
         |
;

jump_stat: CONTINUE ';'
         | BREAK ';'
         | RETURN exp ';'
         | RETURN ';'
;

exp: INTEGER
   | FLOAT
   | CHAR
   | STRING
;
%% 

// Report an error to the user.
extern "C" {
	void yyerror(const char* msg)
	{
		std::cerr << "yyerror: " << msg << '\n';
	}
}

int main ()
{
	yyparse();
	return 0;
}
