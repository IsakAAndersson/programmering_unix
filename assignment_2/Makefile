CC = gcc
CFLAGS = -Wall -Wextra -g
LDFLAGS = -lm

# Default target
all: kmeans run_valgrind

# Object files
kmeans.o: kmeans.c
	$(CC) $(CFLAGS) -c kmeans.c -o kmeans.o

main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

# Executable file
kmeans: kmeans.o main.o
	$(CC) $(CFLAGS) kmeans.o main.o -o kmeans $(LDFLAGS)

# Run program with Valgrind automatically after building
run_valgrind: kmeans
	valgrind --leak-check=full --show-leak-kinds=all ./kmeans

# Clean up
clean:
	rm -f kmeans *.o scatter_plot.png kmeans-output.txt
