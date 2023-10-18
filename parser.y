%{
	#include <iostream>
	using namespace std;

	int yylex();
	extern "C" {
		void yyerror(const char *msg);
	}
	
%}

%token CHARACTER PRINTF SCANF FOR IF ELSE WHILE BOOL_CONST BINARY_OP ASSIGN_OP
NUMBER FLOAT_NUM ID STR ARITHMETIC UNARY HEADER DEFINE RETURN DATATYPE COMP
QUALIFIER CONTINUE BREAK SWITCH CASE

%%
%start program_unit
%%

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
