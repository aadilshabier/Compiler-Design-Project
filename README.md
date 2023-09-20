# Compiler Design Project - CS304

In this project we aim to build a Compiler for the C
language using *Flex++* and *YACC*.

The current deliverables are as follows:
* A lexical analyser using Flex++.

## Usage
The lexer code can be compiled and run on a C file using the following commands:

    flex++ lexer.l
    c++ lex.yy.cc
    ./a.out {file_name}

The {file_name} field should contain the path to the corresponding C program. If the given file name is not valid, the lexer outputs an error message.

## The Lexical Analyser
The lexer identifies the tokens found in the C program and
displays them along with their values, if any. The identifiers along
with the respective details are stored in the symbol table. The
symbol table is printed at the end of the program. The details about
the tokens identified are mentioned in subsequent sections.

If any errors are found during runtime, the lexer stops
traversing through the code and displays an appropriate error
message along with the line number of occurrence.

### Assumptions Made
We have made the following assumptions during the lexer implementation:
* Only ASCII characters are allowed in the code.
* Only the following escape sequences are allowed: ‘\a’, ‘\b’, ‘\e’, ‘\f’, ‘\n’, ‘\r’, ‘\t’, ‘\v’, ‘\\’, ‘\’’, ‘\”’, ‘\?’.
* Only decimal values can be given to corresponding variables, values from other bases are not allowed.
* Among preprocessor directives, only #include, #define are supported. For the current lexical stage, they are ignored.

### Error Identification
The implemented lexer identifies the following errors in the code submitted:
* Identifier variable name crossing a given maximum length, set to 31 by default.
* Strings not containing closing quotes, characters not closed with an inverted colon.
* Multiline comments not ending with the closing symbol - */ .
* Invalid characters.
* Invalid escape sequences.

### Symbol Table
The symbol table contains 6 entries per identifier:
* line number
* identifier type
* scope number
* memory size
* address
* value

We make use of unordered maps from STL for hashing identifier strings
in the symbol table.