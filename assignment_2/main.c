#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>

/* Structures */

// Point structure
struct Point {
    double x;
    double y;
    int cluster;
};

// Cluster structure
struct Cluster {
    struct Point centroid;
    int pointCount;
};


/* Declarations of functions from kmeans.c */
struct Point* readPointsFromFile(const char *filename, int *numberOfPoints);
void initializeClusters(struct Cluster *clusters, int k);
void assignPointsToClusters(struct Point *points, int numberOfPoints, struct Cluster *clusters, int numberOfClusters);
void updateClusterCentroids(struct Cluster *clusters, int numberOfClusters, struct Point *points, int numberOfPoints);

int main(int argc, char *argv[]){

    // Global variables
    int numberOfPoints = 0;
    int numberOfClusters = 0;

    const char *filename = (argc > 1) ? argv[1] : NULL;

    // Read points from file
    struct Point *points = readPointsFromFile(filename, &numberOfPoints);
    if (points == NULL) {
        fprintf(stderr, "Could not read data file\n");
        return 1;
    }

    printf("Read %d points\n", numberOfPoints);

    // Get number of clusters from user
    printf("Enter number of clusters (1-%d): ", numberOfPoints);
    if (scanf("%d", &numberOfClusters) != 1) {
        fprintf(stderr, "Invalid value\n");
        free(points);
        return 1;
    }

    // Ensure valid number of clusters
    if (numberOfClusters < 1) numberOfClusters = 1;
    if (numberOfClusters > numberOfPoints) numberOfClusters = numberOfPoints;

    // Allocate memory for clusters
    struct Cluster *clusters = malloc(sizeof *clusters * numberOfClusters);
    if (clusters == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        free(points);
        return 1;
    }
    // Initialize clusters randomly
    srand((unsigned)time(NULL));
    initializeClusters(clusters, numberOfClusters);

    // Enkel k-means-loop (ingen konvergenskontroll här, lägg till om du vill)
    int maxIterations = 100;
    for (int iteration = 0; iteration < maxIterations; iteration++) {

        // Reset point counts before reassignment
        for (int i = 0; i < numberOfClusters; i++) clusters[i].pointCount = 0;

        assignPointsToClusters(points, numberOfPoints, clusters, numberOfClusters);
        updateClusterCentroids(clusters, numberOfClusters, points, numberOfPoints);
    }

    // Print results (point -> cluster assignments)
    for (int i = 0; i < numberOfPoints; i++) {
        printf("%g\t%g\tcluster %d\n", points[i].x, points[i].y, points[i].cluster);
    }

    // Free allocated memory
    free(clusters);
    free(points);
    return 0;
}