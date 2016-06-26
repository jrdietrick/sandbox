#include "userlib"


int main (
    )
{
    sleep(2);
}

extern "C" void _start (
    )
{
    _exit(main());
}
