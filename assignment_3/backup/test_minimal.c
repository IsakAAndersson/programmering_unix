#include <stdio.h>

extern void start_game(int len, int n_apples);

int main() {
    printf("About to call start_game...\n");
    start_game(5, 2);
    printf("Returned from start_game\n");
    return 0;
}
