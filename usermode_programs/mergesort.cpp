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
    int array[] = {499, -688, -758, -871, -30, 37, -844, 99, -637, -24, 1, -813, -289, 719, 477, 579, -212, -250, 790, -620, 298, -358, 296, 354, 165, 840, 85, -818, 435, 959, 637, 389, 441, 528, 172, -735, -605, -264, -863, 425, -451, 985, 248, 233, -581, 472, 761, 939, 41, -152, 739, 603, -313, -97, -863, -649, -866, 733, 767, -771, -271, -905, -778, 302, 431, -680, 824, -779, -590, 531, 248, -811, 118, 213, 140, -343, 626, -140, 183, -218, 879, -101, -463, 413, -677, 357, 444, -361, -271, 653, -695, 938, -582, -800, 752, -887, -584, 692, 561, 665, 120, -41, 894, 134, 767, -585, -2, -548, -827, -670, 420, -334, -465, 667, 398, -940, 240, 144, 918, -467, 504, -645, 831, 929, -661, 551, 949, 960, 340, 330, 678, 492, -295, 527, -879, 814, -503, 824, -886, 104, -665, 511, 535, -170, 798, 157, 347, -130, 418, -902, -428, 134, 619, 986, 263, -655, -504, 343, -948, -810, -282, 899, 361, 288, 241, 308, 688, 984, -345, 766, -51};
    int* aux_array;
    int length = sizeof(array) / sizeof(int);

    aux_array = (int*)malloc(((sizeof(array) / sizeof(int)) / 2 + 1) * sizeof(int));
    if (!aux_array) {
        _exit(-1);
    }

    sort(array, length, aux_array);

    _exit(check_sort(array, length) ? 0 : -1);
}
