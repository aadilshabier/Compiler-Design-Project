#include <lmao.h>

char b = 'c', d = 'a' + 2;
int *a = 0, *b;

struct i {
	char a[12];
} a[1][4];

int function(int b, char c) {
    int s = 0;
    int i;
	int *iptr = &i;
    for (i=0; i<b; i++) {
        s += c;
    }

	int k = (s == 1) ? 12 : 14;

    return s;
}
