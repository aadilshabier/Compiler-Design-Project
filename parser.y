%{
	#include <iostream>
	#include <cstring>
        #include <unordered_map>
        #include "symbol_table.h"

	using namespace std;

	int yylex();
	extern "C" {
		void yyerror(const char *msg);
	}
        extern FILE* yyin;
	extern int yylineno;

	std::string isOpValid(const std::string& type1, const std::string& op, const std::string& type2);
	int findPriority(const std::string& type);
	char* convertStr(const std::string& str);

	Env env;
%}

%token FOR IF ELSE WHILE DO BOOL_CONST UNARY_OP BINARY_OP ASSIGN_OP SHIFT_CONST
INTEGER FLOAT ID STRING HEADER DEFINE RETURN DATATYPE COMP_OP MEM_OP
QUALIFIER CONTINUE BREAK SWITCH CASE DEFAULT STRUCT UNION CHAR INC_OP END_OF_FILE
%nonassoc "then"
%nonassoc ELSE
%left ','
%left '=' ASSIGN_OP
%right '?'
%left '+' '-'
%left '*' '/' '%'
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
start: { env.newScope(); } program_unit END_OF_FILE { env.endScope(); cout << "Compilation successful!\n"; exit(0);}
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

function_definition: decl_specs { env.currentType = $<str>1; } declarator {
	env.newScope();
	env.inFunction = true;
}
compound_stat {
	env.endScope();
	env.inFunction = false;
}
;

decl: decl_specs { env.currentType = $<str>1;} init_declarator_list ';'
;


struct_decl: STRUCT ID '{' decl_list '}' init_declarator_list ';'
           | STRUCT ID '{' decl_list '}' ';'
;

union_decl: UNION ID '{' decl_list '}' init_declarator_list ';'
          | UNION ID '{' decl_list '}' ';'

decl_list: decl decl_list
         | %empty
;

decl_specs : QUALIFIER DATATYPE {
	char buf[256];
	strcpy(buf, $<str>1);
	strcat(buf, " ");
	strcat(buf, $<str>2);
	$<str>$ = strdup(buf);
}
           | DATATYPE { $<str>$ = $<str>1; }
           | STRUCT ID { $<str>$ = "struct"; }
           | UNION ID { $<str>$ = "union"; }
           | QUALIFIER { $<str>$ = "int"; }
;

param_list: param
          | param ',' param_list
;

param: decl_specs { env.currentType = $<str>1; } declarator { env.currentParams.push_back($<details>3->type); }
;

init_declarator_list: init_declarator
         | init_declarator ',' init_declarator_list
;

init_declarator: declarator
               | declarator '=' initializer
;

initializer     : assignment_exp {$<str>$=$<str>1 ;}
                | '{' initializer_list '}' {$<str>$=$<str>2 ;}
                | '{' initializer_list ',' '}' {$<str>$=$<str>2 ;}
;

initializer_list        : initializer {$<str>$=$<str>1 ;}
                | initializer_list ',' initializer{
                        if(strcmp($<str>1, $<str>3)){
                                cerr<< "ERROR: Type mismatch during initialization at line " << yylineno << endl;
                                exit(1);
                        }
                        $<str>$=$<str>1 ;
                }
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
	details.type = env.currentType;
        	$<details>$ = &details;
 }
| direct_declarator '[' conditional_exp ']' {
	auto *details = $<details>1;
	details->dimension++;
        details->type += '*';
	$<details>$ = $<details>1;
 }
| direct_declarator '[' ']' {
	auto *details = $<details>1;
	details->dimension++;
        details->type += '*';
	$<details>$ = $<details>1;
 }
| direct_declarator '(' { env.currentParams.clear(); } param_list ')' {
	auto *details = $<details>1;
	details->is_func = true;
	details->type += paramsToString(env.currentParams);
 }
| direct_declarator '(' ')' {
	auto *details = $<details>1;
	details->is_func = true;
        details->type += "()";
}
;

stat: exp_stat
    | compound_stat
    | decl
    | jump_stat
    | selection_stat  									  
    | { env.loopCount++; } iteration_stat { env.loopCount--; }
    | labeled_stat
;

exp_stat: exp ';'
        | ';'
;

compound_stat: '{'{ env.newScope(); } stat_list '}' { env.endScope(); }
;

stat_list: stat stat_list
         | %empty
;

selection_stat : IF '(' exp ')' stat 	    %prec "then"
| IF '(' exp ')' stat ELSE stat
| SWITCH { env.switchCount++; } '(' exp ')' stat { env.switchCount--; }
;

opt_exp : exp
        | %empty
;

iteration_stat : WHILE '(' exp ')' stat
| DO stat WHILE '(' exp ')' ';'
| FOR '(' { env.newScope(); } opt_exp ';' opt_exp ';' opt_exp ')' stat { env.endScope(); }
| FOR '(' { env.newScope(); } decl opt_exp ';' opt_exp ')' stat { env.endScope(); }
;

jump_stat: CONTINUE ';' {
	if (env.loopCount < 1) {
		cerr<< "ERROR: Continue outside of loop at line " << yylineno << endl;
		exit(1);
	}
}
| BREAK ';' {
	if (env.loopCount < 1 and env.switchCount < 1) {
		cerr<< "ERROR: Break outside of loop or switch at line " << yylineno << endl;
		exit(1);
	}
}
| RETURN exp ';' {
	if (not env.inFunction) {
		cerr<< "ERROR: Return outside of function at line " << yylineno << endl;
		exit(1);
        }
}
| RETURN ';' {
	if (not env.inFunction) {
		cerr<< "ERROR: Return outside of function at line " << yylineno << endl;
		exit(1);
        }
}
;

labeled_stat: CASE consts ':' stat {
	if (env.switchCount < 1) {
		cerr<< "ERROR: Case outside of switch at line " << yylineno << endl;
		exit(1);
	}
}
| DEFAULT ':' stat {
	if (env.switchCount < 1) {
		cerr<< "ERROR: Default outside of switch at line " << yylineno << endl;
		exit(1);
	}

}

exp : assignment_exp
        | exp ',' assignment_exp
;

assignment_exp : conditional_exp
        | unary_exp ASSIGN_OP assignment_exp
        | unary_exp '=' assignment_exp {
                if(strcmp($<str>1, $<str>3)){
                        cerr<< "ERROR: Type mismatch during assignment at line " << yylineno << endl;
						exit(1);
                }
                $<str>$=$<str>1 ;
        }	
;

argument_exp_list : assignment_exp { env.currentParams.push_back($<str>1); }
| argument_exp_list ',' assignment_exp { env.currentParams.push_back($<str>3); }
;

conditional_exp : logical_exp
        | logical_exp '?' exp ':' assignment_exp
        ;

logical_exp : equality_exp
        | logical_exp logical_oper equality_exp
        ;

logical_oper : '|' | '&' | BINARY_OP
        ;

equality_exp : shift_expression { $<str>$ = $<str>1;}
        | equality_exp COMP_OP shift_expression
        ;

shift_expression : additive_exp { $<str>$ = $<str>1;}
        | shift_expression SHIFT_CONST additive_exp
        ;

additive_exp : mult_exp { $<str>$ = $<str>1;}
        | additive_exp '+' mult_exp { $<str>$ = convertStr(isOpValid($<str>1, "+", $<str>3));}
        | additive_exp '-' mult_exp { $<str>$ = convertStr(isOpValid($<str>1, "-", $<str>3));}
        ;

mult_exp : cast_exp
        | mult_exp '*' cast_exp { $<str>$ = convertStr(isOpValid($<str>1, "*", $<str>3));}
        | mult_exp '/' cast_exp { $<str>$ = convertStr(isOpValid($<str>1, "/", $<str>3));}
        | mult_exp '%' cast_exp { $<str>$ = convertStr(isOpValid($<str>1, "%", $<str>3));}
        ;

cast_exp : unary_exp { $<str>$ = $<str>1; }
        | '(' DATATYPE ')' cast_exp { $<str>$ = $<str>2; }
        ;

unary_exp : postfix_exp { $<str>$ = $<str>1; }
        | INC_OP unary_exp { $<str>$ = $<str>2; }
        | unary_operator cast_exp {
                auto curr_type = std::string($<str>2);
                int degree = $<val>1;
                if(degree<0){
                        if(curr_type.back()!='*'){
                                cerr << "ERROR: Dereferencing a non-pointer object " << $<str>2 << " at line " << yylineno << endl;
                                exit(1);
                        }
                        else curr_type.pop_back();
                }
                else{
                        for(int i=0; i<degree; i++){
                                curr_type += "*";
                        }
                }
                $<str>$ = convertStr(curr_type);
        }
        ;

unary_operator : '+' {$<val>$ = 0;}
        |'-' {$<val>$ = 0;}
        |'&' {$<val>$ = 1;}
        |'*' {$<val>$ = -1;}
        |UNARY_OP {$<val>$ = 0;}
;


postfix_exp : primary_exp { $<str>$ = $<str>1; }
| postfix_exp '[' exp ']' {
	auto type = $<str>1;
	auto len = strlen(type);
	if (type[len-1] != '*') {
		cerr << "ERROR: Dereferencing a non-pointer object " << $<str>1 << " at line " << yylineno << endl;
	}
	type[len-1] = 0;
	$<str>$ = type;
}
| postfix_exp '(' {env.currentParams.clear(); } argument_exp_list ')' {
	auto func_type = $<str>1;
	auto params = typeParams(func_type);
	auto callParams = paramsToString(env.currentParams);
	if (params != callParams) {
		cerr << "ERROR: Function call does not match declaration at line " << yylineno << endl
			 << "Declaration: " << typeParams(func_type) << endl
			 << "Call: " << callParams << endl;
		exit(1);
	}
	$<str>$ = convertStr(typeRoot(func_type));
												}
| postfix_exp '(' {env.currentParams.clear(); } ')' {
	auto func_type = $<str>1;
	auto params = typeParams(func_type);
	auto callParams = paramsToString(env.currentParams);
	if (params != callParams) {
		cerr << "ERROR: Function call does not match declaration at line " << yylineno << endl;
		cerr << "Declaration: " << typeParams(func_type) << "\nCall: " << callParams << endl;
		exit(1);
	}
	$<str>$ = convertStr(typeRoot(func_type));
												}
| postfix_exp MEM_OP ID //skipping
| postfix_exp INC_OP { $<str>$ = $<str>1; }
;

primary_exp : ID {
	if(env.isDeclared($<str>1)) {
		auto &details = env.get($<str>1);
		details.usage_lines.push_back(yylineno);
		$<str>$ = details.type.data();
	} else {
		cerr << "ERROR: ID " << $<str>1 << " not declared at line " << yylineno << endl;
		exit(1);
	}
}
        | consts { $<str>$ = $<str>1; }
        | STRING { $<str>$ = "char*"; }
        | '(' exp ')' { $<str>$ = $<str>2; }
        ;

consts : INTEGER { $<str>$ = "int"; }
        | CHAR  { $<str>$ = "char"; }
        | FLOAT { $<str>$ = "float"; }
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

std::string isOpValid(const std::string& type1, const std::string& op, const std::string& type2){
        int pr1=findPriority(type1), pr2=findPriority(type2);
        string ret = (pr1>=pr2)? type1: type2;

        if(op=="||" || op=="&&"){
                return "int";
        }
        else if(type1.back()=='*' || type2.back()=='*'){ //strings not allowed
                cerr << "ERROR: Invaid operation arguments used for: " << op << " at line " << yylineno << endl;
                exit(1);
        }
        else if(op == "+" || op=="-" || op=="*" || op=="/"){
                return ret;
        }
        else if(op=="%" || op=="^" || op=="|" || op=="&"){
                if(findPriority(ret)>3){
                        cerr << "ERROR: Invaid operation arguments used for: " << op << " at line " << yylineno
			 << " with operands of type " << type1 <<" and " << type2 << endl;
                        exit(1);
                }
                else return ret;
        }
}

int findPriority(const std::string& type){
        static unordered_map<std::string, int> priority = {
                {"char", 1}, {"int", 2}, {"long", 3}, {"float", 4}, {"double", 5}
        };

        if(priority.find(type)!=priority.end()){
                return priority[type];
        }
        else return 0;
}

char* convertStr(const std::string& str){
        return strdup(str.data());
}
