extern "C" {
    #include "userlib.h"
}


void quicksort (
    int* arr,
    int length
    )
{
}


extern "C" void _start (
    )
{
    int arr[] = {4, 6, 7, 1, 2, 5, 8, 3, 9};
    int length = sizeof(arr) / sizeof(int);

    quicksort(arr, length);

    _exit(check_sort(arr, length));
}