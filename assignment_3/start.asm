/* 
Alternative entry point in assembly
Parses command line arguments and starts the game
*/

/*
Stack layout at entry:
rsp+0: argc
rsp+8: argv[0]
rsp+16: argv[1]
rsp+24: argv[2]
*/

.section .data
    usage_msg:      .asciz "Usage: %s LEN APPLES\n"
    
.section .text
.globl _start

# External functions
.extern start_game
.extern printf
.extern atoi
.extern exit



_start:
# Standard entry point for programs compiled without C runtime    
    movq    (%rsp), %rdi
    leaq    8(%rsp), %rsi
    
    # Check if we have enough arguments
    cmpq    $3, %rdi
    jge     parse_args
    
    # Print usage message
    pushq   %rsi
    movq    (%rsi), %rsi
    leaq    usage_msg(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    
    # Exit with code 1
    movl    $1, %edi
    call    exit
    
parse_args:
    # Save argv pointer and align stack
    pushq   %rbx
    pushq   %r12
    pushq   %rsi
    pushq   %rsi
    
    
    # Parse first argument (snake length)
    movq    8(%rsp), %rax
    movq    8(%rax), %rdi
    call    atoi
    movl    %eax, %ebx
    
    # Parse second argument (number of apples)
    movq    8(%rsp), %rax
    movq    16(%rax), %rdi
    call    atoi
    movl    %eax, %r12d
    
    # Clean up alignment padding
    addq    $8, %rsp
    popq    %rsi
    
    # Call start_game with 16-byte aligned stack
    movl    %ebx, %edi
    movl    %r12d, %esi
    call    start_game
    
    # Restore callee-saved registers
    popq    %r12
    popq    %rbx
    
    # Exit with code 0
    xorl    %edi, %edi
    call    exit

# Mark stack as non-executable
.section .note.GNU-stack,"",@progbits
