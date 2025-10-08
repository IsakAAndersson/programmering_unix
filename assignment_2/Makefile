#Objektfiler
kmeans.o: kmeans.c
	$(CC) -c kmeans.c -o kmeans.o

main.o: main.c
	$(CC) -c main.c -o main.o

#Exekverbar fil
kmeans: kmeans.o main.o
	$(CC) kmeans.o main.o -o kmeans -lm

#Rensa upp
clean:
	rm -f kmeans *.o
