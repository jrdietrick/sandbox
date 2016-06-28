#include "userlib"


int main (
    )
{
    sleep(5);
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}
