#ifndef __USERLIB_H__
#define __USERLIB_H__

typedef unsigned char boolean;
#define true 1
#define false 0

void _exit (
    int code
    );

void assert (
    boolean condition
    );

int strlen (
    char* str
    );

int strcmp (
    char* a,
    char* b
    );

void puts (
    char* str
    );

char* itoa (
    int value,
    char* str,
    int base
    );

void* malloc (
    unsigned int size
    );

int check_sort (
    int* array,
    int length
    );

#endif
