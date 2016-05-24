#ifndef __USERLIB_H__
#define __USERLIB_H__

void _exit (
    int code
    );

int strlen (
    char* str
    );

void puts (
    char* str
    );

char* itoa (
    int value,
    char* str,
    int base
    );

int check_sort (
    int* array,
    int length
    );

#endif
