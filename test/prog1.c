#include <stdio.h>

#define MY_DEF

int var1 = 4; // this shouldnt be read
float var2 = -2.78; /*this
					  either*/
char c = '1';

float fexp = 23.0e-12;

int main() {
	printf("Hello, \tWorld: %d\n", var1);
	return 0;
}
