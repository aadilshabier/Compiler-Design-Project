#include "symbol_table.h"

Env::Env()
{
	// global symbol table
	stStack.emplace_back();
}

void Env::newScope()
{
	stStack.emplace_back();
}

void Env::endScope()
{
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
