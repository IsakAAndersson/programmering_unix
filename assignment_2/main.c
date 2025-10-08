#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>

//Point structure
struct Point {
    double x;
    double y;
    int cluster;
};

//Functions
double euclideanDistance(struct Point a, struct Point b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
}

int main(int argc, char *argv[]) {

    FILE *file;
    if (argc > 1) {
        file = fopen(argv[1], "r");
        if (file == NULL) {
            printf("No file found");
            return 1;
        }
    }
    else {
        file = fopen("kmeans-data.txt", "r");
        if (file == NULL) {
            printf("No file found");
            return 1;
        }
    }
    char buffer[128];
    int numberOfPoints = 0;
    struct Point *points = NULL;

    while (fgets(buffer, sizeof(buffer), file)) {
        points = realloc(points, sizeof(struct Point) * (numberOfPoints + 1));
        if (points == NULL) {
            printf("Memory allocation failed");
            return 1;
        }
        sscanf(buffer, "%lf %lf", &points[numberOfPoints].x, &points[numberOfPoints].y);
        numberOfPoints++;
    }

    printf("Enter number of clusters: ");
    int numberOfClusters;
    scanf("%d", &numberOfClusters);


}