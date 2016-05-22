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


int global_arr[] = {499, -688, -758, -871, -30, 37, -844, 99, -637, -24, 1, -813, -289, 719, 477, 579, -212, -250, 790, -620, 298, -358, 296, 354, 165, 840, 85, -818, 435, 959, 637, 389, 441, 528, 172, -735, -605, -264, -863, 425, -451, 985, 248, 233, -581, 472, 761, 939, 41, -152, 739, 603, -313, -97, -863, -649, -866, 733, 767, -771, -271, -905, -778, 302, 431, -680, 824, -779, -590, 531, 248, -811, 118, 213, 140, -343, 626, -140, 183, -218, 879, -101, -463, 413, -677, 357, 444, -361, -271, 653, -695, 938, -582, -800, 752, -887, -584, 692, 561, 665, 120, -41, 894, 134, 767, -585, -2, -548, -827, -670, 420, -334, -465, 667, 398, -940, 240, 144, 918, -467, 504, -645, 831, 929, -661, 551, 949, 960, 340, 330, 678, 492, -295, 527, -879, 814, -503, 824, -886, 104, -665, 511, 535, -170, 798, 157, 347, -130, 418, -902, -428, 134, 619, 986, 263, -655, -504, 343, -948, -810, -282, 899, 361, 288, 241, 308, 688, 984, -345, 766, -51};


extern "C" void _start (
    )
{
    int length = sizeof(global_arr) / sizeof(int);

    heapify(global_arr, length);
    sort(global_arr, length);

    _exit(check_sort(global_arr, length));
}