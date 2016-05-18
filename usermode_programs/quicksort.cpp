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


int choose_pivot (
    int* arr,
    int length
    )
{
    // For simplicity we'll choose the last element
    // of the array as our pivot. This can lead to
    // terrible performance, but we can fix that
    // later.
    return length - 1;
}


void quicksort (
    int* arr,
    int length
    )
{
    int currentIndex;
    int nextFreeIndex;
    int pivotIndex;
    int pivotValue;

    if (length < 2) {
        // Base case, nothing to do.
        return;
    }

    pivotIndex = choose_pivot(arr, length);
    pivotValue = arr[pivotIndex];

    // Move the pivot to the end
    swap(&arr[pivotIndex], &arr[length - 1]);
    pivotIndex = length - 1;

    for (currentIndex = 0, nextFreeIndex = 0;
         currentIndex < pivotIndex;
         currentIndex++) {

        if (arr[currentIndex] > pivotValue) {
            continue;
        }

        swap(&arr[currentIndex], &arr[nextFreeIndex]);
        nextFreeIndex++;
    }

    swap(&arr[nextFreeIndex], &arr[pivotIndex]);
    pivotIndex = nextFreeIndex;

    // Now everything less than or equal to the
    // pivot is left of the pivot, and everything
    // greater than it is right. Recurse.
    quicksort(&arr[0], pivotIndex);
    quicksort(&arr[pivotIndex + 1], length - pivotIndex - 1);
}


extern "C" void _start (
    )
{
    int arr[] = {4, 6, 7, 1, 2, 5, 8, 3, 9};
    int length = sizeof(arr) / sizeof(int);

    quicksort(arr, length);

    _exit(check_sort(arr, length));
}