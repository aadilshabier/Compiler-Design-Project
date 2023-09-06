%{
#include <fstream>

int num_lines = 0, num_words = 0, num_ints = 0, num_specials = 0;
%}

DIGIT	[0-9]
ID		[A-Za-z][A-Za-z0-9]*

%%
\/\/.*$ ;
\/\*(?s:.)*\*\/ ;
[a-zA-Z]+ {
	++num_words;
	// fputs(yytext, yyout);
	yyout << yytext;
}
[0-9]+ {
	++num_ints;
	yyout << yytext;
}
[\n] {
	++num_lines;
	yyout << yytext;
}
[ \t] {
	yyout << yytext;
}
[^A-Za-z0-9] {
	++num_specials;
	yyout << yytext;
}
%%

int yyFlexLexer::yywrap() {
	return 1;
}

int main(int argc, char* argv[]) {
	// if (argc < 2) {
	// 	std::cerr << "You need to supply atleast 2 arguments\n";
	// 	return 1;
	// }
	// yyin = fopen(argv[1], "r");
	// if (not yyin) {
	// 	std::cerr << "Could not open file: " << argv[1] << endl;
	// 	return 1;
	// }
	// yyout = fopen("output.txt", "w");
	// yyout = stdout;
	std::ifstream yyin("./test/prog1.c");
	yyFlexLexer lexer(yyin, std::cout);
	while (lexer.yylex() != 0)
		;

	printf("There are %d lines\n", num_lines);
	printf("There are %d words\n", num_words);
	printf("There are %d integers\n", num_ints);
	printf("There are %d special characters\n", num_specials);
	return 0;
}
