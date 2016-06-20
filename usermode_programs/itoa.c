#include "userlib.h"


void _start (
    )
{
    char number_as_string[16];
    char expected_result[] = "112";
    int length = 0;

    itoa(112, number_as_string, 10);

    if (strcmp(number_as_string, expected_result)) {
        assert(false);
    } else {
        puts("ASSERT OK");
    }

    puts(number_as_string);
    puts("");
    _exit(0);
}