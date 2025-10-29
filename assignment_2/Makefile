SHELL := /bin/bash

# Makefile with automated debugging checks
CC      ?= gcc
CFLAGS  ?= -std=c11 -Wall -Wextra -O2 -g
LDFLAGS ?= -lm

SRCS := kmeans.c main.c
OBJS := $(SRCS:.c=.o)

# Configurable inputs for non-interactive runs
DATA ?= kmeans-data.txt
K    ?= 4

.PHONY: all clean run valgrind gdb check

all: kmeans

kmeans: $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Non-interactive run: pipe K to stdin
run: kmeans
	@echo "Running: ./kmeans $(DATA) (K=$(K))"
	./kmeans "$(DATA)" <<< "$(K)"

# Memory check: fail on any leak/error
valgrind: kmeans
	@echo "Valgrind: $(DATA) (K=$(K))"
	valgrind --leak-check=full --show-leak-kinds=all \
		 --track-origins=yes --errors-for-leak-kinds=all \
		 --error-exitcode=1 \
		 ./kmeans "$(DATA)" <<< "$(K)"

# Batch GDB run to capture backtrace on crash; writes gdb.log
gdb: kmeans
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

clean:
	rm -f kmeans $(OBJS) kmeans-output.txt gdb.log .gdb_in
