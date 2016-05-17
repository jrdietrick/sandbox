#include "userlib.h"


void merge (
    int* arA,
    int* arB,
    int lenA,
    int lenB
    )
{
    int posA = 0;
    int posB = 0;
    int temp = 0;

    for (posA = 0; posA < lenA; posA++) {
        if (arA[posA] <= arB[0]) {
            continue;
        }
        // Swap this element into the beginning of
        // array B
        temp = arA[posA];
        arA[posA] = arB[0];
        // Sort array B again
        for (posB = 1; posB < lenB; posB++) {
            if (arB[posB] >= temp) {
                break;
            }
            arB[posB - 1] = arB[posB];
        }
        arB[posB - 1] = temp;
    }
}


void _start (
    )
{
    int arrayA[] = {6, 8, 10};
    int arrayB[] = {5, 5, 5, 5, 9, 11};
    int lenA = sizeof(arrayA) / sizeof(int);
    int lenB = sizeof(arrayB) / sizeof(int);

    merge(arrayA, arrayB, lenA, lenB);

    //printf("arrayA:\n");
    //for (int i = 0; i < lenA; i++) {
    //    printf("%d\n", arrayA[i]);
    //}

    //printf("arrayB:\n");
    //for (int i = 0; i < lenB; i++) {
    //    printf("%d\n", arrayB[i]);
    //}

    _exit(0);
}
