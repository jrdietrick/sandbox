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
    while (index < length) {
        int leftChildIndex = index * 2 + 1;
        int rightChildIndex = index * 2 + 2;
        int indexOfMax = index;

        if (leftChildIndex >= length) {
            break;
        }

        if (arr[leftChildIndex] > arr[indexOfMax]) {
            indexOfMax = leftChildIndex;
        }

        if (rightChildIndex < length &&
            arr[rightChildIndex] > arr[indexOfMax]) {
            indexOfMax = rightChildIndex;
        }

        if (indexOfMax == index) {
            break;
        }

        swap(&arr[index], &arr[indexOfMax]);
        index = indexOfMax;
    }
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


void sort (
    int *arr,
    int length
    )
{
    for (int cursor = length - 1; cursor > 0; cursor--) {
        swap(&arr[0], &arr[cursor]);
        siftDown(arr, 0, cursor);
    }
}


extern "C" void _start (
    )
{
    int arr[] = {4, 6, 7, 1, 2, 5, 8, 3, 9};
    int length = sizeof(arr) / sizeof(int);

    heapify(arr, length);
    sort(arr, length);

    _exit(0);
}