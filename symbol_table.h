#pragma once

#include <string>
#include <unordered_map>
#include <vector>

// struct Type {
	// bool is_ptr;
	// std::string type_name;
	// Type *inner_type = nullptr;
// };

using Type = std::string;

struct SymbolDetails {
    int decl_line;
	std::vector<int> usage_lines;
	Type type;
	int dimension = 0;
	int size = 0;
	int addr = -1;

	// Function stuff
	bool is_func = false;
};

using SymbolTable = std::unordered_map<std::string, SymbolDetails>;

class Env {
public:
	Env();

	void newScope();

	void endScope();

	/* is the type declared
	 * 0: not declared
	 * 1: declared in any scope, not in current scope
	 * 2: declared in current scope
	 */
    int isDeclared(const std::string& name) const;

	SymbolDetails& put(const std::string &name);
	SymbolDetails& get(const std::string &name);
private:
	static void printParamList(const std::vector<Type> &params);
public:
	int switchCount = 0; // for case, default, break statements
	int loopCount = 0; // for break, continue statements
	bool inFunction = false; // for returns

	Type currentType;
	std::vector<Type> currentParams;
private:
	std::vector<SymbolTable> stStack;
};

Type paramsToString(const std::vector<Type>& params);

Type typeRoot(const Type& type);

Type typeParams(const Type& type);
