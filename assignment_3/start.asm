/*********************************************************************
 *
 * Filename:      start.asm
 * Description:   Alternative entry point in assembly
 *                Parses command line arguments and starts the game
 *
 ********************************************************************/

.section .data
    usage_msg:      .asciz "Usage: %s LEN APPLES\n"
    
.section .text
.globl _start

# External functions
.extern start_game
.extern printf
.extern atoi
.extern exit

/*********************************************************************
 * _start - Program entry point
 * Standard entry point for programs compiled without C runtime
 ********************************************************************/
_start:
    # Stack layout at entry:
    # rsp+0: argc
    # rsp+8: argv[0]
    # rsp+16: argv[1]
    # rsp+24: argv[2]
    
    popq    %rdi                    # argc
    movq    %rsp, %rsi              # argv
    
    # Check if we have enough arguments
    cmpq    $3, %rdi
    jge     parse_args
    
    # Print usage message
    movq    (%rsi), %rsi            # argv[0] (program name)
    leaq    usage_msg(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    
    # Exit with code 1
    movl    $1, %edi
    call    exit
    
parse_args:
    # Save argv pointer
    pushq   %rsi
    
    # Parse first argument (snake length)
    movq    8(%rsi), %rdi           # argv[1]
    call    atoi
    movl    %eax, %ebx              # Save length in ebx
    
    # Parse second argument (number of apples)
    popq    %rsi
    movq    16(%rsi), %rdi          # argv[2]
    call    atoi
    movl    %eax, %ecx              # Save apples in ecx
    
    # Call start_game
    movl    %ebx, %edi              # First parameter: length
    movl    %ecx, %esi              # Second parameter: apples
    call    start_game
    
    # Exit with code 0
    xorl    %edi, %edi
    call    exit

# Mark stack as non-executable
.section .note.GNU-stack,"",@progbits
