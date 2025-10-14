CC = gcc
CFLAGS = -Wall -Wextra -g
LDFLAGS = -lm


# Default target
all: kmeans

# Object files
kmeans.o: kmeans.c
	$(CC) $(CFLAGS) -c kmeans.c -o kmeans.o

main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

# Executable file
kmeans: kmeans.o main.o
	$(CC) $(CFLAGS) kmeans.o main.o -o kmeans $(LDFLAGS)

# Clean up
clean:
	rm -f kmeans *.o
