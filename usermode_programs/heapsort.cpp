extern "C" {
    #include "userlib.h"
}


void swap (
    int* a,
    int* b
    )
{
    int swap = *a;
    *a = *b;
    *b = swap;
}


void siftDown (
    int* arr,
    int index,
    int length
    )
{
    int leftChildIndex = index * 2 + 1;
    int rightChildIndex = index * 2 + 2;
    int indexOfMax = index;

    if (leftChildIndex >= length) {
        // This is a leaf node! Nothing to do.
        return;
    }

    if (arr[leftChildIndex] > arr[indexOfMax]) {
        indexOfMax = leftChildIndex;
    }

    if (rightChildIndex < length &&
        arr[rightChildIndex] > arr[indexOfMax]) {
        indexOfMax = rightChildIndex;
    }

    if (indexOfMax == index) {
        // Nothing to do.
        return;
    }

    swap(&arr[indexOfMax], &arr[index]);

    siftDown(arr, indexOfMax, length);
}


void heapify (
    int* arr,
    int length
    )
{
    int lastParent = (length - 2) / 2;

    for (int index = lastParent; index >= 0; index--) {
        siftDown(arr, index, length);
    }
}


extern "C" void _start (
    )
{
    int arr[] = {4, 6, 7, 1, 2, 5, 8, 3, 9};
    int length = sizeof(arr) / sizeof(int);

    heapify(arr, length);

    _exit(0);
}