#include "userlib"


int main (
    )
{
    printf("----\n");
    printf("%d\n", fgetc(0));
    printf("----\n");
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}
