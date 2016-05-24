#ifndef __USERLIB_H__
#define __USERLIB_H__

void _exit (
    int code
    );

int check_sort (
    int* array,
    int length
    );

char* itoa (
    int value,
    char* str,
    int base
    );

#endif
