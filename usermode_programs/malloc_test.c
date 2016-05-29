#include "userlib.h"


void _start (
    )
{
    int* my_tiny_array = (int*)malloc(sizeof(int) * 4);
    int* my_tiny_array2 = (int*)malloc(sizeof(int) * 4);
    int* my_medium_array = (int*)malloc(sizeof(int) * 16);
    int* my_4k_slab = (int*)malloc(4096);

    assert(my_tiny_array && my_tiny_array2 && my_medium_array && my_4k_slab);
    assert(malloc(4095));
    assert(malloc(4097) == NULL);

    my_tiny_array[0] = 256;
    my_tiny_array2[3] = -1;
    my_medium_array[60] = 0xbaadf00d;

    _exit(0);
}