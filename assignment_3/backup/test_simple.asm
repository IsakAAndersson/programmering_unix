.section .text
.globl test_func

.extern board_init

test_func:
    pushq   %rbp
    movq    %rsp, %rbp
    
    call    board_init
    call    game_exit
    
    movq    %rbp, %rsp
    popq    %rbp
    ret

.extern game_exit
