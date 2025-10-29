# Snake Game - x86-64 Assembly Implementation

This is a snake game implemented in x86-64 assembly language using AT&T syntax.

## Building the Game

To compile the game:
```bash
make
```

This will create two executables:
- `snake_asm` - Entry point from C main()
- `snake_asm_start` - Entry point from assembly _start()

To clean build artifacts:
```bash
make clean
```

## Running the Game

Run with two command-line arguments:
1. Initial snake length (e.g., 5)
2. Number of apples (e.g., 2)

Example:
```bash
./snake_asm 5 2
```

Or:
```bash
./snake_asm_start 5 2
```

## Controls

- **Arrow Keys**: Control snake direction (Up, Down, Left, Right)
- **Q**: Quit the game

## Gameplay

- The snake starts at the center of the board moving right
- The snake continuously moves in the current direction
- Eating an apple ('@') makes the snake grow by one segment
- The snake dies if it collides with itself
- The snake wraps around when hitting the edges of the board
- New apples appear when one is eaten

## Implementation Details

- Board size: 80x24 characters
- Snake represented by 'O' characters
- Apples represented by '@' characters
- Written entirely in x86-64 assembly (AT&T syntax)
- Uses ncurses library for terminal graphics
- Follows System V AMD64 ABI calling conventions

## Files

- `snake.asm` - Main game logic (assembly)
- `start.asm` - Alternative entry point (assembly)
- `main.c` - C entry point
- `helpers.c` - Helper functions for ncurses
- `workaround.asm` - Required symbols for nostdlib linking
- `Makefile` - Build configuration
