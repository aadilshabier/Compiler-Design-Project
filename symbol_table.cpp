#include "symbol_table.h"
#include <iostream>

Env::Env()
{
}

void Env::newScope()
{
	stStack.emplace_back();
}

void Env::endScope()
{
	for (auto xy: stStack.back()) {
		std::cout << xy.first
				  << " of type " << xy.second.type
				  << " at line " << xy.second.decl_line
				  << " with dimension " << xy.second.dimension
				  << std::endl;
	}
	stStack.pop_back();
}

int Env::isDeclared(const std::string& name) const {
	int len = stStack.size();
	for (int i=len-1; i>=0; i--) {
		const SymbolTable &curST = stStack[i];
		if (curST.find(name) != curST.end()) {
			return (i == len-1) ? 2 : 1;
		}
	}
	return 0;
}

SymbolDetails& Env::put(const std::string &name) {
	return stStack.back()[name];
}

SymbolDetails& Env::get(const std::string &name) {
	int len = stStack.size();
	for (int i=len-1; i>=0; i--) {
		SymbolTable &curST = stStack[i];
		if (auto it = curST.find(name); it != curST.end()) {
			return it->second;
		}
	}
}

void Env::printParamList(const std::vector<Type> &params)
{
	std::cout << '(';
	for (const auto &p : params) {
		std::cout << p << ", ";
	}
	std::cout << ')';
}

Type paramsToString(const std::vector<Type>& params) {
    Type result;
	result += '(';
	int n = params.size();
	for (int i=0; i<n; i++) {
		result += params[i];
		if (i != n-1) {
			result += ',';
		}
	}
	result += ')';
	return result;
}

Type typeRoot(const Type& type) {
	auto it = type.find('(');
	return type.substr(0, it);
}

Type typeParams(const Type& type) {
	auto it = type.find('(');
	return type.substr(it);
}
