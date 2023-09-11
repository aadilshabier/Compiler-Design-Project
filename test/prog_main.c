#include <stdio.h>

int num_0 = 41;
char c = '1';
const float fexp = 23.0e-12;


int main() {

    // Print the number
    printf("The number: %d", num_0);

    /*
    The number is even if the
    remainder is 0
    */

    while (num_0 >= 2) num_0 -= 2;


    if (num_0 == 0) printf("The given number is even.\n");
    else printf("The given number is odd.\n");

    return 0;
}
