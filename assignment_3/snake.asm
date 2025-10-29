/*********************************************************************
 *
 * Filename:      snake.asm
 * Description:   Snake game implementation in x86-64 assembly
 *                Uses AT&T syntax
 *
 ********************************************************************/

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
    snake_x:        .space MAX_SNAKE_LEN * 4  # X coordinates of snake segments
    snake_y:        .space MAX_SNAKE_LEN * 4  # Y coordinates of snake segments
    snake_len:      .int 0                     # Current snake length
    direction:      .int DIR_RIGHT             # Current direction
    apples_x:       .space 100 * 4             # X coordinates of apples
    apples_y:       .space 100 * 4             # Y coordinates of apples
    num_apples:     .int 0                     # Number of apples on board
    game_speed:     .int 100000                # Game speed (microseconds)
    tail_x:         .int 0                     # Last tail X position
    tail_y:         .int 0                     # Last tail Y position
    grow_pending:   .int 0                     # Flag to indicate growth pending
    just_grew:      .int 0                     # Flag indicating we just grew this frame
    
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

/*********************************************************************
 * start_game - Main game entry point
 * Parameters:
 *   %edi - initial snake length
 *   %esi - number of apples
 ********************************************************************/
start_game:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp                # Align stack to 16 bytes
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    # Save parameters
    movl    %edi, %r12d             # r12 = initial snake length
    movl    %esi, %r13d             # r13 = number of apples
    
    # Initialize board
    call    board_init
    
    # Draw border
    call    draw_border
    
    # Initialize game state
    movl    %r12d, %edi
    movl    %r13d, %esi
    call    init_game
    
    # Main game loop
game_loop:
    # Get keyboard input
    xorl    %eax, %eax
    call    board_get_key
    movl    %eax, %ebx              # Save key in ebx
    
    # Process input if key was pressed
    cmpl    $-1, %ebx
    je      skip_input
    
    # Check for quit key
    cmpl    $KEY_Q, %ebx
    je      game_over
    
    # Update direction based on key
    movl    %ebx, %edi
    call    update_direction
    
skip_input:
    # Move snake
    call    move_snake
    
    # Check for collisions
    call    check_collision
    cmpl    $0, %eax
    jne     game_over
    
    # Check for apple eating
    call    check_apple
    
    # Draw everything
    call    draw_game
    
    # Sleep for game speed
    movl    game_speed(%rip), %edi
    call    usleep
    
    # Continue loop
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

/*********************************************************************
 * init_game - Initialize game state
 * Parameters:
 *   %edi - initial snake length
 *   %esi - number of apples
 ********************************************************************/
init_game:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp                # Align stack to 16 bytes
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    
    movl    %edi, %r12d             # Save initial length
    movl    %esi, %r13d             # Save number of apples
    
    # Set snake length
    movl    %r12d, snake_len(%rip)
    
    # Initialize grow flags
    movl    $0, grow_pending(%rip)
    movl    $0, just_grew(%rip)
    
    # Initialize snake position (center of board)
    movl    $BOARD_WIDTH, %eax
    shrl    $1, %eax                # eax = width / 2
    movl    $BOARD_HEIGHT, %ebx
    shrl    $1, %ebx                # ebx = height / 2
    
    # Initialize snake segments
    xorl    %ecx, %ecx              # Counter
init_snake_loop:
    cmpl    %r12d, %ecx
    jge     init_snake_done
    
    # Sign extend counter for array indexing
    movslq  %ecx, %r8
    
    # Calculate x position (moving left from center)
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
    cmpl    %r13d, %ecx
    jge     init_apple_done
    
    movl    %ecx, %ebx
    pushq   %rcx                    # Save counter across function call
    call    place_apple
    popq    %rcx                    # Restore counter
    incl    %ecx
    jmp     init_apple_loop
    
init_apple_done:
    popq    %r13
    popq    %r12
    popq    %rbx
    leave
    ret

/*********************************************************************
 * place_apple - Place an apple at random position
 * Parameters:
 *   %ebx - apple index
 ********************************************************************/
place_apple:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    
    # Save apple index
    movl    %ebx, %r12d
    
    # Generate random X coordinate (1 to BOARD_WIDTH-1)
    call    rand
    xorl    %edx, %edx
    movl    $BOARD_WIDTH, %ecx
    subl    $2, %ecx                # Width - 2 (range for values 1 to WIDTH-1)
    cmpl    $1, %ecx
    jge     do_x_div
    movl    $1, %ecx                # Safety: minimum range of 1
do_x_div:
    divl    %ecx                    # edx = rand % (BOARD_WIDTH-2)
    incl    %edx                    # edx = 1 to BOARD_WIDTH-1
    
    # Sign extend apple index for array indexing
    movslq  %r12d, %r8
    leaq    apples_x(%rip), %rdi
    movl    %edx, (%rdi,%r8,4)
    
    # Generate random Y coordinate (1 to BOARD_HEIGHT-1)
    call    rand
    xorl    %edx, %edx
    movl    $BOARD_HEIGHT, %ecx
    subl    $2, %ecx                # Height - 2 (range for values 1 to HEIGHT-1)
    cmpl    $1, %ecx
    jge     do_y_div
    movl    $1, %ecx                # Safety: minimum range of 1
do_y_div:
    divl    %ecx                    # edx = rand % (BOARD_HEIGHT-2)
    incl    %edx                    # edx = 1 to BOARD_HEIGHT-1
    
    movslq  %r12d, %r8
    leaq    apples_y(%rip), %rdi
    movl    %edx, (%rdi,%r8,4)
    
    popq    %r12
    popq    %rbx
    leave
    ret

/*********************************************************************
 * update_direction - Update snake direction based on key
 * Parameters:
 *   %edi - key code
 ********************************************************************/
update_direction:
    pushq   %rbp
    movq    %rsp, %rbp
    
    movl    direction(%rip), %eax
    
    # Check UP key
    cmpl    $KEY_UP, %edi
    jne     check_down
    cmpl    $DIR_DOWN, %eax         # Cannot go up if going down
    je      update_dir_done
    movl    $DIR_UP, direction(%rip)
    jmp     update_dir_done
    
check_down:
    cmpl    $KEY_DOWN, %edi
    jne     check_left
    cmpl    $DIR_UP, %eax           # Cannot go down if going up
    je      update_dir_done
    movl    $DIR_DOWN, direction(%rip)
    jmp     update_dir_done
    
check_left:
    cmpl    $KEY_LEFT, %edi
    jne     check_right
    cmpl    $DIR_RIGHT, %eax        # Cannot go left if going right
    je      update_dir_done
    movl    $DIR_LEFT, direction(%rip)
    jmp     update_dir_done
    
check_right:
    cmpl    $KEY_RIGHT, %edi
    jne     update_dir_done
    cmpl    $DIR_LEFT, %eax         # Cannot go right if going left
    je      update_dir_done
    movl    $DIR_RIGHT, direction(%rip)
    
update_dir_done:
    movq    %rbp, %rsp
    popq    %rbp
    ret

/*********************************************************************
 * move_snake - Move the snake in current direction
 ********************************************************************/
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
    decl    %r13d                   # r13d = tail index
    
    # Sign extend to 64-bit for array indexing
    movslq  %r13d, %r13
    
    leaq    snake_x(%rip), %rdi
    movl    (%rdi,%r13,4), %r12d
    movl    %r12d, tail_x(%rip)
    
    leaq    snake_y(%rip), %rdi
    movl    (%rdi,%r13,4), %r12d
    movl    %r12d, tail_y(%rip)
    
    # Get current head position
    leaq    snake_x(%rip), %rdi
    movl    (%rdi), %eax            # eax = head x
    leaq    snake_y(%rip), %rdi
    movl    (%rdi), %ebx            # ebx = head y
    
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
    movl    $1, just_grew(%rip)     # Set flag that we just grew
    movl    snake_len(%rip), %edx
    incl    %edx
    movl    %edx, snake_len(%rip)
    
    # Shift all segments to make room for new head
    movl    snake_len(%rip), %ecx
    decl    %ecx                    # Start from last segment (new position)
    
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
    decl    %ecx                    # Start from last segment
    
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
    # Set new head position
    leaq    snake_x(%rip), %rdi
    movl    %eax, (%rdi)
    leaq    snake_y(%rip), %rdi
    movl    %ebx, (%rdi)
    
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    movq    %rbp, %rsp
    popq    %rbp
    ret

/*********************************************************************
 * check_collision - Check if snake hits itself
 * Returns:
 *   %eax - 1 if collision, 0 otherwise
 ********************************************************************/
check_collision:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    
    # Get head position
    leaq    snake_x(%rip), %rdi
    movl    (%rdi), %eax
    leaq    snake_y(%rip), %rdi
    movl    (%rdi), %ebx
    
    # Check against body (starting from segment 1)
    movl    $1, %ecx
check_coll_loop:
    cmpl    snake_len(%rip), %ecx
    jge     no_collision
    
    # Sign extend counter for array indexing
    movslq  %ecx, %r8
    
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
    movq    %rbp, %rsp
    popq    %rbp
    ret

/*********************************************************************
 * check_apple - Check if snake eats an apple
 ********************************************************************/
check_apple:
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    
    # Get head position
    leaq    snake_x(%rip), %rdi
    movl    (%rdi), %eax
    leaq    snake_y(%rip), %rdi
    movl    (%rdi), %ebx
    
    # Check each apple
    xorl    %ecx, %ecx
check_apple_loop:
    cmpl    num_apples(%rip), %ecx
    jge     check_apple_done
    
    # Sign extend counter for array indexing
    movslq  %ecx, %r8
    
    leaq    apples_x(%rip), %rdi
    cmpl    %eax, (%rdi,%r8,4)
    jne     check_apple_next
    
    leaq    apples_y(%rip), %rdi
    cmpl    %ebx, (%rdi,%r8,4)
    jne     check_apple_next
    
    # Apple eaten! Set grow flag
    movl    $1, grow_pending(%rip)
    
    # Place new apple
    movl    %ecx, %ebx
    call    place_apple
    jmp     check_apple_done
    
check_apple_next:
    incl    %ecx
    jmp     check_apple_loop
    
check_apple_done:
    popq    %r12
    popq    %rbx
    movq    %rbp, %rsp
    popq    %rbp
    ret

/*********************************************************************
 * draw_border - Draw a border frame around the game area
 ********************************************************************/
draw_border:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp                # Align stack
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    
    # Draw top-left corner
    xorl    %edi, %edi              # x = 0
    xorl    %esi, %esi              # y = 0
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    # Draw top border
    movl    $1, %r12d               # x counter
draw_top_border:
    cmpl    $BOARD_WIDTH, %r12d
    jge     draw_top_right_corner
    
    movl    %r12d, %edi             # x
    xorl    %esi, %esi              # y = 0
    movl    $CHAR_HORIZONTAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    incl    %r12d
    jmp     draw_top_border
    
draw_top_right_corner:
    movl    $BOARD_WIDTH, %edi      # x
    xorl    %esi, %esi              # y = 0
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    # Draw bottom-left corner
    xorl    %edi, %edi              # x = 0
    movl    $BOARD_HEIGHT, %esi     # y
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    # Draw bottom border
    movl    $1, %r12d
draw_bottom_border:
    cmpl    $BOARD_WIDTH, %r12d
    jge     draw_bottom_right_corner
    
    movl    %r12d, %edi             # x
    movl    $BOARD_HEIGHT, %esi     # y
    movl    $CHAR_HORIZONTAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    incl    %r12d
    jmp     draw_bottom_border
    
draw_bottom_right_corner:
    movl    $BOARD_WIDTH, %edi      # x
    movl    $BOARD_HEIGHT, %esi     # y
    movl    $CHAR_CORNER, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    # Draw left border
    movl    $1, %r12d               # y counter
draw_left_border:
    cmpl    $BOARD_HEIGHT, %r12d
    jge     draw_right_border_start
    
    xorl    %edi, %edi              # x = 0
    movl    %r12d, %esi             # y
    movl    $CHAR_VERTICAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    incl    %r12d
    jmp     draw_left_border
    
draw_right_border_start:
    movl    $1, %r12d               # y counter
draw_right_border:
    cmpl    $BOARD_HEIGHT, %r12d
    jge     draw_border_done
    
    movl    $BOARD_WIDTH, %edi      # x
    movl    %r12d, %esi             # y
    movl    $CHAR_VERTICAL, %edx
    xorl    %eax, %eax
    call    board_put_char
    
    incl    %r12d
    jmp     draw_right_border
    
draw_border_done:
    popq    %r13
    popq    %r12
    popq    %rbx
    leave
    ret

/*********************************************************************
 * draw_game - Draw the game state
 ********************************************************************/
draw_game:
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $8, %rsp                # Align stack to 16 bytes
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
    # Draw snake
    xorl    %ecx, %ecx
draw_snake_loop:
    cmpl    snake_len(%rip), %ecx
    jge     draw_snake_done
    
    # Sign extend counter for array indexing
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
    # Draw apples
    xorl    %ecx, %ecx
draw_apple_loop:
    cmpl    num_apples(%rip), %ecx
    jge     draw_apple_done
    
    # Sign extend counter for array indexing
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
