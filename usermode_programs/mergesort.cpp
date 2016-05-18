extern "C" {
    #include "userlib.h"
}


void merge (
    int* array,
    int splitIndex,
    int length,
    int* auxArray
    )
{
    // First copy everything left of the split to
    // the aux array
    for (int i = 0; i < splitIndex; i++) {
        auxArray[i] = array[i];
    }

    // Now merge!
    int leftIndex = 0;
    int leftMax = splitIndex;
    int rightIndex = splitIndex;
    int rightMax = length;

    for (int i = 0; i < length; i++) {
        if (leftIndex == leftMax) {
            array[i] = array[rightIndex];
            rightIndex++;
        } else if (rightIndex == rightMax) {
            array[i] = auxArray[leftIndex];
            leftIndex++;
        } else if (auxArray[leftIndex] <= array[rightIndex]) {
            array[i] = auxArray[leftIndex];
            leftIndex++;
        } else {
            array[i] = array[rightIndex];
            rightIndex++;
        }
    }
}


void sort (
    int* array,
    int length,
    int* auxArray
    )
{
    if (length < 2) {
        // Base case, we're already sorted!
        return;
    }

    // Pick a split
    int splitIndex = length / 2;

    // Sort the subarrays
    sort(&array[0], splitIndex, auxArray);
    sort(&array[splitIndex], length - splitIndex, auxArray);

    // Now merge the two back together.
    merge(array,
          splitIndex,
          length,
          auxArray);
}


extern "C" void _start (
    )
{
    int array[] = {4, 6, 7, 1, 2, 5, 8, 3, 9};
    int auxArray[5];
    int length = sizeof(array) / sizeof(int);

    // Since we don't have memory allocation, this
    // will have to do for now. Make sure we don't
    // have a mismatch between our aux array and
    // array to sort.
    if (sizeof(auxArray) < sizeof(array) / 2 + 1) {
        _exit(-1);
    }

    sort(array, length, auxArray);

    _exit(check_sort(array, length));
}
