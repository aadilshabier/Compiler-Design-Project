%{
	#include <iostream>
	#include <cstring>
    #include "symbol_table.h"

	using namespace std;

	int yylex();
	extern "C" {
		void yyerror(const char *msg);
	}
    extern FILE* yyin;
	extern int yylineno;

	Env env;
	Type currentType;
	vector<Type> currentParams;
%}

%token FOR IF ELSE WHILE DO BOOL_CONST UNARY_OP BINARY_OP ASSIGN_OP SHIFT_CONST
INTEGER FLOAT ID STRING HEADER DEFINE RETURN DATATYPE COMP_OP MEM_OP
QUALIFIER CONTINUE BREAK SWITCH CASE STRUCT UNION CHAR INC_OP END_OF_FILE
%nonassoc "then"
%nonassoc ELSE
%left ','
%left '=' ASSIGN_OP
%right '?'
%left '+' '-'
%left '*' '/'
%left MEM_OP
%left '(' '['
%left INC_OP

%union {
	char* str;
	SymbolDetails *details;
	int val;
}

%start start

%%
start: { env.newScope(); } program_unit END_OF_FILE { cout << "Compilation successful!\n"; env.endScope(); exit(0);}
;

program_unit: HEADER program_unit
            | DEFINE program_unit
            | translation_unit
;

translation_unit: external_decl translation_unit
                | %empty
;

external_decl: function_definition
             | decl
             | struct_decl
             | union_decl
;

function_definition: decl_specs { currentType = $<str>1; env.newScope(); } declarator compound_stat { env.endScope(); } 
;

decl: decl_specs { currentType = $<str>1;} init_declarator_list ';'
;


struct_decl: STRUCT ID '{' decl_list '}' init_declarator_list ';'
           | STRUCT ID '{' decl_list '}' ';'
;

union_decl: UNION ID '{' decl_list '}' init_declarator_list ';'
          | UNION ID '{' decl_list '}' ';'

decl_list: decl decl_list
         | %empty
;

decl_specs : QUALIFIER DATATYPE { $<str>$ = $<str>2; }
           | DATATYPE { $<str>$ = $<str>1; }
           | STRUCT ID { $<str>$ = "struct"; }
           | UNION ID { $<str>$ = "union"; }
           | QUALIFIER { $<str>$ = "int"; }
;

param_list: param
          | param ',' param_list
;

param: decl_specs { currentType = $<str>1; } declarator { currentParams.push_back($<details>3->type); }
;

init_declarator_list: init_declarator
         | init_declarator ',' init_declarator_list
;

init_declarator: declarator
               | declarator '=' exp
;

declarator: pointer direct_declarator {
	int ptr_count = $<val>1;
	auto* details = $<details>2;
	for (int i=0; i<ptr_count; i++)
		details->type+='*';
	$<details>$ = details;
 }
          | direct_declarator
;

pointer: '*' pointer { $<val>$ = $<val>2 + 1; }
| '*' { $<val>$ = 1; }
;

direct_declarator: ID {
	std::string idName = $<str>1;
	auto res = env.isDeclared(idName);
	if (res == 2) {
	    cerr << "ERROR: Redeclaration of: " << idName << endl;
		exit(1);
	}
	auto &details = env.put(idName);
	details.decl_line = yylineno;
	details.type = currentType;
	$<details>$ = &details;
 }
| direct_declarator '[' conditional_exp ']' {
	auto *details = $<details>1;
	details->dimension++;
	$<details>$ = $<details>1;
 }
| direct_declarator '[' ']' {
	auto *details = $<details>1;
	details->dimension++;
	$<details>$ = $<details>1;
 }
| direct_declarator '(' { currentParams.clear(); } param_list ')' {
	auto *details = $<details>1;
	details->is_func = true;
	details->params = currentParams;
 }
| direct_declarator '(' ')' {
	auto *details = $<details>1;
	details->is_func = true;
 }
;

stat: exp_stat
    | compound_stat
    | decl
    | jump_stat
    | selection_stat  									  
	| iteration_stat
;

exp_stat: exp ';'
        | ';'
;

compound_stat: '{'stat_list '}'
;

stat_list: stat stat_list
         | %empty
;

selection_stat : IF '(' exp ')' stat 	    %prec "then"
        | IF '(' exp ')' stat ELSE stat
        | SWITCH '(' exp ')' stat
;

opt_exp : exp
        | %empty
;

iteration_stat : WHILE '(' exp ')' stat
        | DO stat WHILE '(' exp ')' ';'
        | FOR '(' opt_exp ';' opt_exp ';' opt_exp ')' stat
        | FOR '(' decl opt_exp ';' opt_exp ')' stat
;

jump_stat: CONTINUE ';'
         | BREAK ';'
         | RETURN exp ';'
         | RETURN ';'
;

exp : assignment_exp
        | exp ',' assignment_exp
;
assignment_exp : conditional_exp
        | unary_exp ASSIGN_OP assignment_exp
        | unary_exp '=' assignment_exp			
;

conditional_exp : logical_exp
        | logical_exp '?' exp ':' assignment_exp
        ;

logical_exp : equality_exp
        | logical_exp logical_oper equality_exp
        ;

logical_oper : '|' | '&' | BINARY_OP
        ;

equality_exp : shift_expression
        | equality_exp COMP_OP shift_expression
        ;

shift_expression : additive_exp
        | shift_expression SHIFT_CONST additive_exp
        ;

additive_exp : mult_exp
        | additive_exp '+' mult_exp
        | additive_exp '-' mult_exp
        ;

mult_exp : cast_exp
        | mult_exp '*' cast_exp
        | mult_exp '/' cast_exp
        | mult_exp '%' cast_exp
        ;

cast_exp : unary_exp
        | '(' DATATYPE ')' cast_exp
        ;

unary_exp : postfix_exp
        | INC_OP unary_exp
        | unary_operator cast_exp
        ;

unary_operator : '+'|'-'|'&'| '*' |UNARY_OP
;

postfix_exp : primary_exp
        | postfix_exp '[' exp ']'
        | postfix_exp '(' argument_exp_list ')'
        | postfix_exp '(' ')'
        | postfix_exp MEM_OP ID
        | postfix_exp INC_OP
        ;
                            
primary_exp : ID 													
        | consts 												
        | STRING 												
        | '(' exp ')'
        ;

argument_exp_list : assignment_exp
        | argument_exp_list ',' assignment_exp
        ;

consts : INTEGER 											
        | CHAR
        | FLOAT
        ;

%%

// Report an error to the user.
extern "C" {
	void yyerror(const char* msg)
	{
		std::cerr << "yyerror at line "  << yylineno << ": " << msg << '\n';
	}
}

int main(int argc, char* argv[]) {
	if (argc < 2) {
		std::cerr << "ERROR: filename not given!\n";
		return 1;
	}
	/* std::ifstream yyin(argv[1]); */
    yyin = fopen(argv[1], "r");
	if (yyin == nullptr) {
		std::cerr << "ERROR: file does not exist: " << argv[1] << std::endl;
		return 1;
	}
    
	yyparse();
	return 0;
}
