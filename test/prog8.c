#include <lmao.h>

char b = 'c', d = 'a' + 2;

int function(int b, char c) {
    int s = 0;
    int i;
    for (i=0; i<b; i++) {
        s += c;
    }
    return s;
}