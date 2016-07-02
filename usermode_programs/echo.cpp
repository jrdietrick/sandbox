#include "userlib"


int main (
    )
{
    char buffer[64];
    fgets(buffer, 64, 0);
    printf("%s\n", buffer);
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}
