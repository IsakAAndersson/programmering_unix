/* Description:   Snake game implementation in x86-64 assembly. Uses AT&T syntax*/

/* -------------------------

CODE EXPLANATION

pushq   %rbp
movq    %rsp, %rbp
    Standard function prologue to set up stack frame. 

subq    $8, %rsp
    Align stack to 16-byte boundary for function calls that require it.

leave == movq    %rbp, %rsp
         popq    %rbp
    Clean up stack frame before returning from function.

<global_variable>(%rip) == current value of global_variable
    Accessing global variables using RIP-relative addressing.

%edi - first integer parameter
    Standard calling convention for passing parameters in registers.

%esi - second integer parameter
    Standard calling convention for passing parameters in registers.

%rax / %eax - return value register (64 bit / 32 bit)
    Standard calling convention for returning values from functions.

xorl %eax, %eax
    Efficient way to set %eax to zero. (instead of movl $0, %eax)

movslq %ecx, %r8
    Sign-extend 32-bit integer in %ecx to 64-bit in %r8 for array indexing.

.space SIZE * 4
    Allocate memory space for an array of SIZE integers (4 bytes each as integers are 4 bytes).

------------------------------*/


.section .data
    # Board dimensions
    .equ BOARD_WIDTH, 80
    .equ BOARD_HEIGHT, 24
    
    # Direction constants
    .equ DIR_UP, 0
    .equ DIR_DOWN, 1
    .equ DIR_LEFT, 2
    .equ DIR_RIGHT, 3
    
    # Key codes
    .equ KEY_UP, 259
    .equ KEY_DOWN, 258
    .equ KEY_LEFT, 260
    .equ KEY_RIGHT, 261
    .equ KEY_Q, 113
    
    # Game characters
    .equ CHAR_SNAKE, 'O'
    .equ CHAR_APPLE, '@'
    .equ CHAR_SPACE, ' '
    .equ CHAR_CORNER, '+'
    .equ CHAR_HORIZONTAL, '-'
    .equ CHAR_VERTICAL, '|'
    
    # Maximum snake length
    .equ MAX_SNAKE_LEN, 1000
    
    # Game state variables
    snake_x:        .space MAX_SNAKE_LEN * 4   
    snake_y:        .space MAX_SNAKE_LEN * 4
    snake_len:      .int 0
    direction:      .int DIR_RIGHT
    apples_x:       .space 100 * 4
    apples_y:       .space 100 * 4
    num_apples:     .int 0
    game_speed:     .int 100000
    tail_x:         .int 0
    tail_y:         .int 0
    grow_pending:   .int 0
    just_grew:      .int 0

    # Strings
    score_str:      .asciz "Score: "

.section .text
.globl start_game

# External C functions
.extern board_init
.extern board_get_key
.extern board_put_char
.extern board_put_str
.extern game_exit
.extern usleep
.extern rand

start_game:
# Main game start function, initializing base state
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp                
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    # Save parameters in safe registers
    movl    %edi, %r12d           
    movl    %esi, %r13d             
    
    call    board_init
    call    draw_border

    movl    %r12d, %edi
    movl    %r13d, %esi
    call    init_game
    
game_loop:
# Main game loop: input, movement, collision, rendering
    xorl    %eax, %eax
    call    board_get_key
    movl    %eax, %ebx              
    
    cmpl    $-1, %ebx
    je      skip_input
    
    cmpl    $KEY_Q, %ebx
    je      game_over
    
    movl    %ebx, %edi
    call    update_direction
   
skip_input:
# Skip direction update, continue current direction with current speed
    call    move_snake  
    call    check_collision
    cmpl    $0, %eax

    jne     game_over  
 
    call    check_apple   
    call    draw_game  
    movl    game_speed(%rip), %edi
    call    usleep 

    jmp     game_loop

game_over:
    call    game_exit  
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    leave
    ret

init_game:
# Initialize game state with snake length, apple count and start positions
# Save snake length and number of apples to safe registers (r12d, r13d)
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp                
    pushq   %rbx
    pushq   %r12
    pushq   %r13

    movl    %edi, %r12d
    movl    %esi, %r13d

    movl    %r12d, snake_len(%rip)
    
    movl    $0, grow_pending(%rip)
    movl    $0, just_grew(%rip)
    
    movl    $BOARD_WIDTH, %eax
    shrl    $1, %eax                
    movl    $BOARD_HEIGHT, %ebx
    shrl    $1, %ebx 

    xorl    %ecx, %ecx    

init_snake_loop:
    cmpl    %r12d, %ecx
    jge     init_snake_done
    
    movslq  %ecx, %r8

    # Set x position (center, moving left)
    movl    %eax, %edx
    subl    %ecx, %edx
    leaq    snake_x(%rip), %rdi
    movl    %edx, (%rdi,%r8,4)
    
    # Set y position (center)
    leaq    snake_y(%rip), %rdi
    movl    %ebx, (%rdi,%r8,4)
    
    incl    %ecx
    jmp     init_snake_loop
    
init_snake_done:
    # Set initial direction
    movl    $DIR_RIGHT, direction(%rip)
    
    # Initialize apples
    movl    %r13d, num_apples(%rip)
    xorl    %ecx, %ecx

init_apple_loop:
    # Place initial apples
    cmpl    %r13d, %ecx
    jge     init_apple_done
    
    movl    %ecx, %ebx
    pushq   %rcx
    call    place_apple
    popq    %rcx
    incl    %ecx
    jmp     init_apple_loop
    
init_apple_done:
    popq    %r13
    popq    %r12
    popq    %rbx
    leave
    ret

place_apple:
    # place_apple - Place an apple at random position
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    movl    %ebx, %r12d

retry_position:
    # Generate random X coordinate (1 to BOARD_WIDTH-1)
    call    rand
    xorl    %edx, %edx
    movl    $BOARD_WIDTH, %ecx
    subl    $2, %ecx
    cmpl    $1, %ecx
    jge     do_x_div
    movl    $1, %ecx

do_x_div:
    divl    %ecx
    incl    %edx
    movl    %edx, %r13d
    
    # Generate random Y coordinate (1 to BOARD_HEIGHT-1)
    call    rand
    xorl    %edx, %edx
    movl    $BOARD_HEIGHT, %ecx
    subl    $2, %ecx
    cmpl    $1, %ecx
    jge     do_y_div
    movl    $1, %ecx
do_y_div:
    divl    %ecx
    incl    %edx
    movl    %edx, %r14d
    
    # Check if position overlaps with snake
    xorl    %ecx, %ecx
check_overlap_loop:
    cmpl    snake_len(%rip), %ecx
    jge     snake_position_ok
    
    movslq  %ecx, %r8
    leaq    snake_x(%rip), %rdi
    cmpl    %r13d, (%rdi,%r8,4)
    jne     check_next_segment
    
    leaq    snake_y(%rip), %rdi
    cmpl    %r14d, (%rdi,%r8,4)
    jne     check_next_segment
    
    jmp     retry_position
    
check_next_segment:
    incl    %ecx
    jmp     check_overlap_loop

snake_position_ok:
    xorl    %r10d, %r10d

check_apple_overlap:
    cmpl    num_apples(%rip), %r10d
    jge     apple_position_ok
    
    cmpl    %r12d, %r10d
    je      next_apple_check
    
    movslq  %r10d, %r11
    leaq    apples_x(%rip), %rdi
    cmpl    %r13d, (%rdi,%r11,4)
    jne     next_apple_check
    
    leaq    apples_y(%rip), %rdi
    cmpl    %r14d, (%rdi,%r11,4)
    jne     next_apple_check
    
    jmp     retry_position
    
next_apple_check:
    incl    %r10d
    jmp     check_apple_overlap

apple_position_ok:
    movslq  %r12d, %r8
    leaq    apples_x(%rip), %rdi
    movl    %r13d, (%rdi,%r8,4)
    
    leaq    apples_y(%rip), %rdi
    movl    %r14d, (%rdi,%r8,4)
    
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    leave
    ret


update_direction:
/*
update_direction - Update snake direction based on key
Comparing with current direction to prevent 180-degree turns.
*/
    pushq   %rbp
    movq    %rsp, %rbp  
    movl    direction(%rip), %eax
    
# Check UP key
    cmpl    $KEY_UP, %edi
    jne     check_down
    cmpl    $DIR_DOWN, %eax
    je      update_dir_done
    movl    $DIR_UP, direction(%rip)
    jmp     update_dir_done
    
check_down:
    cmpl    $KEY_DOWN, %edi
    jne     check_left
    cmpl    $DIR_UP, %eax
    je      update_dir_done
    movl    $DIR_DOWN, direction(%rip)
    jmp     update_dir_done
    
check_left:
    cmpl    $KEY_LEFT, %edi
    jne     check_right
    cmpl    $DIR_RIGHT, %eax
    je      update_dir_done
    movl    $DIR_LEFT, direction(%rip)
    jmp     update_dir_done
    
check_right:
    cmpl    $KEY_RIGHT, %edi
    jne     update_dir_done
    cmpl    $DIR_LEFT, %eax
    je      update_dir_done
    movl    $DIR_RIGHT, direction(%rip)
    
update_dir_done:
    leave
    ret

move_snake:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    # Save current tail position before moving
    movl    snake_len(%rip), %r13d
    decl    %r13d
    
    movslq  %r13d, %r13
    
    leaq    snake_x(%rip), %rdi
    movl    (%rdi,%r13,4), %r12d
    movl    %r12d, tail_x(%rip)
    
    leaq    snake_y(%rip), %rdi
    movl    (%rdi,%r13,4), %r12d
    movl    %r12d, tail_y(%rip)
    
    # Get current head position
    movl    snake_x(%rip), %eax
    movl    snake_y(%rip), %ebx
    
    # Calculate new head position based on direction
    movl    direction(%rip), %ecx
    cmpl    $DIR_UP, %ecx
    jne     check_move_down
    decl    %ebx
    # Wrap around (stay within borders 1 to BOARD_HEIGHT-1)
    cmpl    $1, %ebx
    jge     move_done_calc
    movl    $BOARD_HEIGHT, %ebx
    decl    %ebx
    jmp     move_done_calc
    
check_move_down:
    cmpl    $DIR_DOWN, %ecx
    jne     check_move_left
    incl    %ebx
    # Wrap around (stay within borders 1 to BOARD_HEIGHT-1)
    movl    $BOARD_HEIGHT, %edx
    decl    %edx
    cmpl    %edx, %ebx
    jle     move_done_calc
    movl    $1, %ebx
    jmp     move_done_calc
    
check_move_left:
    cmpl    $DIR_LEFT, %ecx
    jne     check_move_right
    decl    %eax
    # Wrap around (stay within borders 1 to BOARD_WIDTH-1)
    cmpl    $1, %eax
    jge     move_done_calc
    movl    $BOARD_WIDTH, %eax
    decl    %eax
    jmp     move_done_calc
    
check_move_right:
    incl    %eax
    # Wrap around (stay within borders 1 to BOARD_WIDTH-1)
    movl    $BOARD_WIDTH, %edx
    decl    %edx
    cmpl    %edx, %eax
    jle     move_done_calc
    movl    $1, %eax
    
move_done_calc:
    # Reset just_grew flag
    movl    $0, just_grew(%rip)
    
    # Check if we need to grow
    movl    grow_pending(%rip), %edx
    cmpl    $0, %edx
    je      no_grow
    
    # Growing: don't shift, just add new head
    movl    $0, grow_pending(%rip)
    movl    $1, just_grew(%rip)
    movl    snake_len(%rip), %edx
    incl    %edx
    movl    %edx, snake_len(%rip)
    
    # Shift all segments to make room for new head
    movl    snake_len(%rip), %ecx
    decl    %ecx
    
grow_shift_loop:
    cmpl    $0, %ecx
    jle     grow_shift_done
    
    # Copy from index ecx-1 to index ecx
    movl    %ecx, %edx
    decl    %edx
    
    # Convert to 64-bit for array indexing (use r14/r15 as temps)
    movslq  %ecx, %r14
    movslq  %edx, %r15
    
    leaq    snake_x(%rip), %rdi
    movl    (%rdi,%r15,4), %r12d
    movl    %r12d, (%rdi,%r14,4)
    
    leaq    snake_y(%rip), %rdi
    movl    (%rdi,%r15,4), %r12d
    movl    %r12d, (%rdi,%r14,4)
    
    decl    %ecx
    jmp     grow_shift_loop
    
grow_shift_done:
    jmp     set_new_head
    
no_grow:
    # Shift snake body (move from tail to head)
    movl    snake_len(%rip), %ecx
    decl    %ecx
    
shift_loop:
    cmpl    $0, %ecx
    jle     shift_done
    
    # Copy position from segment i-1 to segment i
    movl    %ecx, %edx
    decl    %edx
    
    # Convert to 64-bit for array indexing (use r14/r15 as temps)
    movslq  %ecx, %r14
    movslq  %edx, %r15
    
    leaq    snake_x(%rip), %rdi
    movl    (%rdi,%r15,4), %r12d
    movl    %r12d, (%rdi,%r14,4)
    
    leaq    snake_y(%rip), %rdi
    movl    (%rdi,%r15,4), %r12d
    movl    %r12d, (%rdi,%r14,4)
    
    decl    %ecx
    jmp     shift_loop
    
shift_done:
set_new_head:
    leaq    snake_x(%rip), %rdi
    movl    %eax, (%rdi)
    leaq    snake_y(%rip), %rdi
    movl    %ebx, (%rdi)
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    leave
    ret

check_collision:
/*
Check if snake hits itself by getting head position and 
checking against body segment by segment, boolean return
*/
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    
    # Get head position
    movl    snake_x(%rip), %eax
    movl    snake_y(%rip), %ebx
    
    movl    $1, %ecx

check_coll_loop:
    cmpl    snake_len(%rip), %ecx
    jge     no_collision
    
    movslq  %ecx, %r8
    
    # Get segment position
    leaq    snake_x(%rip), %rdi
    cmpl    %eax, (%rdi,%r8,4)
    jne     check_coll_next
    
    leaq    snake_y(%rip), %rdi
    cmpl    %ebx, (%rdi,%r8,4)
    jne     check_coll_next
    
    # Collision detected
    movl    $1, %eax
    jmp     check_coll_done
    
check_coll_next:
    incl    %ecx
    jmp     check_coll_loop
    
no_collision:
    xorl    %eax, %eax
    
check_coll_done:
    popq    %rbx
    leave
    ret


check_apple:
# Check if snake eats an apple and handle growth and speed increase
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12

    # Get head position
    movl    snake_x(%rip), %eax
    movl    snake_y(%rip), %ebx

    xorl    %ecx, %ecx

check_apple_loop:
    cmpl    num_apples(%rip), %ecx
    jge     check_apple_done
    
    movslq  %ecx, %r8
    
    leaq    apples_x(%rip), %rdi
    cmpl    %eax, (%rdi,%r8,4)
    jne     check_apple_next
    
    leaq    apples_y(%rip), %rdi
    cmpl    %ebx, (%rdi,%r8,4)
    jne     check_apple_next
    
    movl    $1, grow_pending(%rip)
    
    # Increase speed (decrease delay by 5%)
    movl    game_speed(%rip), %eax
    imull   $19, %eax
    xorl    %edx, %edx
    movl    $20, %r12d
    divl    %r12d
    
    # Check minimum speed (10ms = 10000 microseconds)
    cmpl    $10000, %eax
    jge     speed_ok
    movl    $10000, %eax

speed_ok:
    movl    %eax, game_speed(%rip)
    
    movl    %ecx, %ebx
    call    place_apple
    jmp     check_apple_done
    
check_apple_next:
    incl    %ecx
    jmp     check_apple_loop
    
check_apple_done:
    popq    %r12
    popq    %rbx
    leave
    ret


draw_border:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp
    pushq   %r12
    
    # Draw all four corners
    # Top-left corner (0, 0)
    xorl    %edi, %edi
    xorl    %esi, %esi
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char

    # Top-right corner (WIDTH, 0)
    movl    $BOARD_WIDTH, %edi
    xorl    %esi, %esi
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char

    # Bottom-left corner (0, HEIGHT)
    xorl    %edi, %edi
    movl    $BOARD_HEIGHT, %esi
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char

    # Bottom-right corner (WIDTH, HEIGHT)
    movl    $BOARD_WIDTH, %edi
    movl    $BOARD_HEIGHT, %esi
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    movl    $1, %r12d

draw_horizontal:
    cmpl    $BOARD_WIDTH, %r12d
    jge     draw_vertical_setup
    
    # Top border
    movl    %r12d, %edi
    xorl    %esi, %esi
    movl    $CHAR_HORIZONTAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    # Bottom border
    movl    %r12d, %edi
    movl    $BOARD_HEIGHT, %esi
    movl    $CHAR_HORIZONTAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    incl    %r12d
    jmp     draw_horizontal
    
draw_vertical_setup:
    movl    $1, %r12d

draw_vertical:
    cmpl    $BOARD_HEIGHT, %r12d
    jge     draw_border_done
    
    # Left border
    xorl    %edi, %edi
    movl    %r12d, %esi
    movl    $CHAR_VERTICAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    # Right border
    movl    $BOARD_WIDTH, %edi
    movl    %r12d, %esi
    movl    $CHAR_VERTICAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    incl    %r12d
    jmp     draw_vertical
    
draw_border_done:
    popq    %r12
    leave
    ret

draw_game:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    
    # Erase old tail if not growing
    movl    just_grew(%rip), %eax
    cmpl    $0, %eax
    jne     skip_erase_tail
    
    movl    tail_x(%rip), %edi
    movl    tail_y(%rip), %esi
    movl    $CHAR_SPACE, %edx
    xorl    %eax, %eax
    call    board_put_char
    
skip_erase_tail:
    xorl    %ecx, %ecx

draw_snake_loop:
    cmpl    snake_len(%rip), %ecx
    jge     draw_snake_done
    
    movslq  %ecx, %r13
    
    leaq    snake_x(%rip), %rdi
    movl    (%rdi,%r13,4), %edi
    leaq    snake_y(%rip), %rsi
    movl    (%rsi,%r13,4), %esi
    movl    $CHAR_SNAKE, %edx
    
    movq    %rcx, %r12
    xorl    %eax, %eax
    call    board_put_char
    movq    %r12, %rcx
    
    incl    %ecx
    jmp     draw_snake_loop
    
draw_snake_done:
    xorl    %ecx, %ecx

draw_apple_loop:
    cmpl    num_apples(%rip), %ecx
    jge     draw_apple_done

    movslq  %ecx, %r13
    
    leaq    apples_x(%rip), %rdi
    movl    (%rdi,%r13,4), %edi
    leaq    apples_y(%rip), %rsi
    movl    (%rsi,%r13,4), %esi
    movl    $CHAR_APPLE, %edx
    
    movq    %rcx, %r12
    xorl    %eax, %eax
    call    board_put_char
    movq    %r12, %rcx
    
    incl    %ecx
    jmp     draw_apple_loop
    
draw_apple_done:
    popq    %r13
    popq    %r12
    popq    %rbx
    leave
    ret

# Mark stack as non-executable
.section .note.GNU-stack,"",@progbits
