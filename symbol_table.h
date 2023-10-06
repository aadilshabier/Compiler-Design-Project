#include <string>
#include <unordered_map>
#include <vector>

struct SymbolDetails {
	std::vector<int> linenos;
	std::string type;
	int scopeno = -1;
	int size = 0;
	int addr = -1;
	std::string value;
};

using SymbolTable = std::unordered_map<std::string, SymbolDetails>;
