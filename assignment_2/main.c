#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>

/* Predefined constants */
#define MAX_ITERATIONS 1000 //maximum number of iterations in clustering to prevent infinite loops
#define EPSILON 0.01    //minimum change in centroid position to continue

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
    if (numberOfClusters < 1){
        int oldNumberOfClusters = numberOfClusters;
        numberOfClusters = 1;
        printf("Number of clusters: %d < 1: set to minimum value of 1\n", oldNumberOfClusters);
    }
    if (numberOfClusters > numberOfPoints){
        int oldNumberOfClusters = numberOfClusters;
        numberOfClusters = numberOfPoints;
        printf("Number of clusters: %d > %d: set to maximum value of %d\n", oldNumberOfClusters, numberOfPoints, numberOfPoints);
    }
    printf("Using %d clusters\n", numberOfClusters);


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

    // K-means algorithm iterations
    int iteration = 0;
    int converged = 0;

while (!converged && iteration < MAX_ITERATIONS) {
    iteration++;
    
    // Save old centroids for convergence check
    struct Point oldCentroids[numberOfClusters];
    for (int i = 0; i < numberOfClusters; i++) {
        oldCentroids[i] = clusters[i].centroid;
        clusters[i].pointCount = 0; // reset before reassignment
    }

    assignPointsToClusters(points, numberOfPoints, clusters, numberOfClusters);
    updateClusterCentroids(clusters, numberOfClusters, points, numberOfPoints);

    // Check if centroids have changed significantly
    converged = 1;
    for (int i = 0; i < numberOfClusters; i++) {
        double dx = clusters[i].centroid.x - oldCentroids[i].x;
        double dy = clusters[i].centroid.y - oldCentroids[i].y;
        if (dx*dx + dy*dy > EPSILON*EPSILON) {
            converged = 0;
            break;
        }
    }
}


    // Open output file or create if it doesn't exist
    FILE *outfile = fopen("kmeans-output.txt", "w");
    if (outfile == NULL) {
        fprintf(stderr, "Could not open output file\n");
        free(clusters);
        free(points);
        return 1;
    }
    
    // Write results to file (point -> cluster assignments)
    for (int i = 0; i < numberOfPoints; i++) {
        fprintf(outfile, "%g\t%g\t%d\n", points[i].x, points[i].y, points[i].cluster);
    }
    
    // Close output file
    fclose(outfile);
    printf("Results written to kmeans-output.txt\n");
    
    // Free allocated memory
    free(clusters);
    free(points);
    return 0;
}