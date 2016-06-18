#ifndef __USERLIB_H__
#define __USERLIB_H__

#define true 1
#define false 0

#define NULL 0

#define INT_MAX ((int)0x7fffffff)
#define INT_MIN ((int)0x80000000)

void _exit (
    int code
    );

void assert (
    unsigned int condition
    );

int strlen (
    char* str
    );

int strcmp (
    char* a,
    char* b
    );

void strcpy (
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

void printf (
    char* format_string,
    int test_integer
    );

void* malloc (
    unsigned int size
    );

void free (
    void* freed_region
    );

int check_sort (
    int* array,
    int length
    );

#endif
