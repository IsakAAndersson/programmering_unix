#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/*----------- Structures -----------*/
struct Point {
    double x;
    double y;
    int cluster;
};

struct Cluster {
    struct Point centroid;
    int pointCount;
};

/*---------- Functions -----------*/
//Create the clusters with random centroids
void initializeClusters(struct Cluster *clusters, int k) {
    for (int i = 0; i < k; i++) {
        clusters[i].centroid.x = (rand() % 61) - 30; // Random x between -30 and 30
        clusters[i].centroid.y = (rand() % 61) - 30; // Random y between -30 and 30
        clusters[i].pointCount = 0;
    }
}

//Calculate Euclidean distance between two points
double euclideanDistance(struct Point a, struct Point b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
}

//Assign points to the nearest cluster
void assignPointsToClusters(struct Point *points, int numberOfPoints, 
                            struct Cluster *clusters, int numberOfClusters) {
    for (int i = 0; i < numberOfPoints; i++) {
        double minDistance = INFINITY;
        int closestCluster = -1;
        
        for (int j = 0; j < numberOfClusters; j++) {
            double distance = euclideanDistance(points[i], clusters[j].centroid);
            if (distance < minDistance) {
                minDistance = distance;
                closestCluster = j;
            }
        }
        points[i].cluster = closestCluster;
        clusters[closestCluster].pointCount++;
    }
}

//Recalculate centroids of clusters based on average of assigned points
void updateClusterCentroids(struct Cluster *clusters, int numberOfClusters, 
                            struct Point *points, int numberOfPoints) {
    for (int i = 0; i < numberOfClusters; i++) {
        double sumX = 0;
        double sumY = 0;
        int count = 0;
        
        for (int j = 0; j < numberOfPoints; j++) {
            if (points[j].cluster == i) {
                sumX += points[j].x;
                sumY += points[j].y;
                count++;
            }
        }
        
        if (count > 0) {
            clusters[i].centroid.x = sumX / count;
            clusters[i].centroid.y = sumY / count;
        }
    }
}

//Read file and load points into an array
struct Point* readPointsFromFile(const char *filename, int *numberOfPoints) {
    //Default file if none provided
    if (filename == NULL) {
        filename = "kmeans-data.txt";
    }
    
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        printf("No file found\n");
        return NULL;
    }
    
    // Dynamically allocate memory for points
    size_t capacity = 100;
    size_t MAX_CAPACITY = 10000;
    struct Point *points = malloc(sizeof(struct Point) * capacity);
    if (points == NULL) {
        printf("Memory allocation failed\n");
        fclose(file);
        return NULL;
    }
    
    // Read points from file
    *numberOfPoints = 0;
    while (fscanf(file, "%lf %lf", &points[*numberOfPoints].x, 
                  &points[*numberOfPoints].y) == 2) {
        points[*numberOfPoints].cluster = -1;
        (*numberOfPoints)++;
        
        // Resize array if needed
        if ((size_t)(*numberOfPoints) >= capacity && capacity < MAX_CAPACITY) { //Make numberOfPoints size_t to compare with capacity
            capacity *= 2;
            struct Point *temp = realloc(points, sizeof(struct Point) * capacity);
            if (temp == NULL) {
                printf("Memory allocation failed\n");
                free(points);
                fclose(file);
                return NULL;
            }
            points = temp;
        }
    }
    
    fclose(file);
    return points;
}