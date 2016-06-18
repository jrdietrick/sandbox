#include "userlib"


int main (
    )
{
    printf("test\n", 9);
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}