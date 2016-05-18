extern "C" {
    #include "userlib.h"
}


void sort (
    int* array,
    int length,
    int* aux_array
    )
{
}


extern "C" void _start (
    )
{
    int array[] = {4, 6, 7, 1, 2, 5, 8, 3, 9};
    int aux_array[9];
    int length = sizeof(array) / sizeof(int);

    // Since we don't have memory allocation, this
    // will have to do for now. Make sure we don't
    // have a mismatch between our aux array and
    // array to sort.
    if (sizeof(aux_array) < sizeof(array)) {
        _exit(-1);
    }

    sort(array, length, aux_array);

    _exit(check_sort(array, length));
}
