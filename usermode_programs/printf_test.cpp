#include "userlib"


int main (
    )
{
    printf("test                                                     test\n", 9);
    printf("test                                                      test\n", 9);
    printf("test                                                       test\n", 9);
    printf("test                                                        test\n", 9);
    printf("test                                                         test\n", 9);
    printf("test %d test\n", 1);
    printf("test                      %d                                test\n", 9);
    printf("test                                                     test%d\n", 9);
    printf("test                                                      test%d\n", 9);
    printf("test                                                       test%d\n", 9);
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}