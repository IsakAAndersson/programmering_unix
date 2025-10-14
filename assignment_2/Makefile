SHELL := /bin/bash # Bash needed for check features

# Makefile with automated debugging checks

# $@ - target
# $< - first prerequisite
# $^ - all prerequisites

# Compiler and flags
CC      ?= gcc
CFLAGS  ?= -std=c11 -Wall -Wextra -O2 -g
LDFLAGS ?= -lm

# Source and object files
SRCS := kmeans.c main.c
OBJS := $(SRCS:.c=.o)

# Configurable inputs
DATA ?= kmeans-data.txt
K    ?= 4

# Targets
.PHONY: all clean run valgrind gdb check

# Default target
all: kmeans

# Build kmeans executable
kmeans: $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Run on data with K clusters
run: kmeans
	@echo "Running: ./kmeans $(DATA) (K=$(K))"
	./kmeans "$(DATA)" <<< "$(K)"

# Memory check with Valgrind
valgrind: kmeans
	@if ! command -v valgrind &> /dev/null; then \
		echo "Valgrind is not installed!"; \
		exit 1; \
	fi
	@echo "Valgrind: $(DATA) (K=$(K))"
	valgrind --leak-check=full --show-leak-kinds=all \
		 --track-origins=yes --errors-for-leak-kinds=all \
		 --error-exitcode=1 \
		 ./kmeans "$(DATA)" <<< "$(K)"

# Write gdb test output to gdb.log
gdb: kmeans
	@if ! command -v gdb &> /dev/null; then \
		echo "GDB is not installed!"; \
		exit 1; \
	fi
	@echo "GDB batch: $(DATA) (K=$(K)) -> gdb.log"
	@echo "$(K)" > .gdb_in
	@gdb -q -batch -ex "set pagination off" \
		 -ex "run < .gdb_in" -ex "bt full" \
		 --args ./kmeans "$(DATA)" > gdb.log 2>&1 || true
	@rm -f .gdb_in

# Automated check: valgrind + gdb + basic output validation
check: valgrind gdb
	@in_lines=$$(wc -l < "$(DATA)"); \
	out_lines=$$(wc -l < kmeans-output.txt 2>/dev/null || echo 0); \
	if [[ $$in_lines -ne $$out_lines ]]; then \
		echo "Mismatch: input ($$in_lines) != output ($$out_lines)"; \
		exit 1; \
	else \
		echo "OK: $$out_lines lines"; \
	fi

# Clean build and log files
clean:
	rm -f kmeans $(OBJS) kmeans-output.txt gdb.log .gdb_in scatter_plot.png
