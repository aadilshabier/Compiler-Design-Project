%{
	#include <iostream>
	using namespace std;

	int yylex();
	extern "C" {
		void yyerror(const char *msg);
	}
	
%}

%token HEADER DEFINE TYPE QUALIFIER IF FOR WHILE CONTINUE ELSE SWITCH CASE BREAK RETURN AND OR NOT COMP SELFOP PAREN OP FLOAT INTEGER ID CHAR STRING

%%
start: HEADER
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
