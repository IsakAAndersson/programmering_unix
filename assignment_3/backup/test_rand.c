#include <stdlib.h>
#include <stdio.h>
#include <time.h>

int main() {
    srand(time(0));
    int r = rand();
    printf("rand = %d\n", r);
    return 0;
}
