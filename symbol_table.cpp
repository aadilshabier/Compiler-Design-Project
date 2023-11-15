#include "symbol_table.h"
#include <iostream>
#include <iomanip>

std::string SymbolDetails::usage_lines_str() const
{
	std::string result;
	for (int i=0; i<usage_lines.size(); i++) {
		result += std::to_string(usage_lines[i]);
		if (i != usage_lines.size()-1)
			result += ' ';
	}
	return result;
}


Env::Env()
{
}

void Env::newScope()
{
	stStack.emplace_back();
}

void Env::endScope()
{
	printSymbolTable(stStack.back());
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

void Env::printSymbolTable(const SymbolTable &st)
{
	if (st.size() == 0)
		return;

	constexpr int WIDTH = 20;
	std::cout << std::setw(WIDTH) << "NAME" << std::setw(WIDTH) << "DECLARATION LINE" << std::setw(WIDTH) << "USAGE LINES"
			  << std::setw(WIDTH) << "TYPE" << std::setw(WIDTH) << "DIMENSION" << std::setw(WIDTH) << "FUNCTION" << std::endl;
	for (const auto& [name, details]: st) {
		std::cout << std::setw(WIDTH) << name << std::setw(WIDTH) << details.decl_line << std::setw(WIDTH) << details.usage_lines_str()
				  << std::setw(WIDTH) << details.type << std::setw(WIDTH) << details.dimension << std::setw(WIDTH) << details.is_func << std::endl;
	}
	std::cout << std::endl;
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
