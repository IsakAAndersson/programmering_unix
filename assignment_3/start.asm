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
    
    # At program entry, stack is 16-byte aligned
    # We need to keep it aligned for function calls
    
    movq    (%rsp), %rdi            # argc (without popping)
    leaq    8(%rsp), %rsi           # argv (pointer to first element)
    
    # Check if we have enough arguments
    cmpq    $3, %rdi
    jge     parse_args
    
    # Print usage message
    # Need to save argv for later, and align stack
    pushq   %rsi                    # Save argv (also aligns stack for call)
    movq    (%rsi), %rsi            # argv[0] (program name)
    leaq    usage_msg(%rip), %rdi
    xorl    %eax, %eax
    call    printf
    
    # Exit with code 1
    movl    $1, %edi
    call    exit
    
parse_args:
    # Save argv pointer and align stack
    # We need to preserve argv across calls and maintain alignment
    pushq   %rbx                    # Callee-saved register for length
    pushq   %r12                    # Callee-saved register for apples
    pushq   %rsi                    # Save argv pointer
    
    # Stack is now misaligned (pushed 3 times = 24 bytes)
    # Need one more push to align to 16 bytes
    pushq   %rsi                    # Dummy push for alignment
    
    # Stack layout now:
    # 0(%rsp) = dummy rsi
    # 8(%rsp) = saved rsi (argv pointer)
    # 16(%rsp) = saved r12
    # 24(%rsp) = saved rbx
    
    # Parse first argument (snake length)
    movq    8(%rsp), %rax           # Get saved argv from stack
    movq    8(%rax), %rdi           # argv[1] - pointer to first arg string
    call    atoi
    movl    %eax, %ebx              # Save length in ebx
    
    # Parse second argument (number of apples)
    movq    8(%rsp), %rax           # Get saved argv from stack
    movq    16(%rax), %rdi          # argv[2] - pointer to second arg string
    call    atoi
    movl    %eax, %r12d             # Save apples in r12d
    
    # Clean up alignment padding
    addq    $8, %rsp
    popq    %rsi                    # Restore (but we don't need it anymore)
    
    # Call start_game with 16-byte aligned stack
    movl    %ebx, %edi              # First parameter: length
    movl    %r12d, %esi             # Second parameter: apples
    call    start_game
    
    # Restore callee-saved registers
    popq    %r12
    popq    %rbx
    
    # Exit with code 0
    xorl    %edi, %edi
    call    exit

# Mark stack as non-executable
.section .note.GNU-stack,"",@progbits
