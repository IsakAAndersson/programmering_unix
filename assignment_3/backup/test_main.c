#include <stdio.h>

extern void test_func();

int main() {
    printf("Calling test_func...\n");
    test_func();
    printf("Success!\n");
    return 0;
}
