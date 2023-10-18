%{
	#include <iostream>
	using namespace std;

	int yylex();
	extern "C" {
		void yyerror(const char *msg);
	}
    extern FILE* yyin;
	extern int yylineno;
%}

%token FOR IF ELSE WHILE DO BOOL_CONST UNARY_OP BINARY_OP ASSIGN_OP SHIFT_CONST
INTEGER FLOAT ID STRING HEADER DEFINE RETURN DATATYPE COMP_OP MEM_OP
QUALIFIER CONTINUE BREAK SWITCH CASE STRUCT CHAR INC_OP
%nonassoc "then"
%nonassoc ELSE
%left '+' '-'
%left '*' '/'
%start start

%%
start: program_unit {exit(0);}
;

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
                   | decl_specs ID '(' ')' compound_stat
;

decl: decl_specs init_declarator_list ';'
;

decl_specs : QUALIFIER DATATYPE
           | DATATYPE
           | QUALIFIER
;

param_list: param
          | param ',' param_list
;

param: decl_specs ID
     | decl_specs
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
    | selection_stat  									  
	| iteration_stat
;

exp_stat: exp ';'
        | ';'
;

compound_stat: '{'stat_list '}'
;

stat_list: stat stat_list
         |
;

selection_stat : IF '(' exp ')' stat 	    %prec "then"
        | IF '(' exp ')' stat ELSE stat
        | SWITCH '(' exp ')' stat
;

opt_exp : exp
        |
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
        | logical_exp '?' exp ':' conditional_exp
        ;

logical_exp : equality_exp
        | logical_exp logical_oper equality_exp
        ;

logical_oper : '&' | BINARY_OP
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

unary_operator : '+'|'-'|'&'|'*'| UNARY_OP 				
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
	}
	/* std::ifstream yyin(argv[1]); */
    yyin = fopen(argv[1], "r");
	if (yyin == nullptr) {
		std::cerr << "ERROR: file does not exist: " << argv[1] << std::endl;
	}
    
	yyparse();
	return 0;
}