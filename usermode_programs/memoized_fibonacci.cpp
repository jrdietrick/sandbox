#include "userlib"


int getFibonacciNumberByOrdinal (
    int* memoized,
    int ordinal
    )
{
    int index = ordinal - 1;

    if (memoized[index] != -1) {
        return memoized[index];
    }

    if (memoized[index - 2] == -1) {
        memoized[index - 2] = getFibonacciNumberByOrdinal(memoized, ordinal - 2);
    }

    if (memoized[index - 1] == -1) {
        memoized[index - 1] = getFibonacciNumberByOrdinal(memoized, ordinal - 1);
    }

    return memoized[index - 1] + memoized[index - 2];
}

#define HARDCODED_ORDINAL 40

int main (
    )
{
    int* memoized = nullptr;
    memoized = new int[HARDCODED_ORDINAL];
    memoized[0] = 1;
    memoized[1] = 1;
    for (int i = 2; i < HARDCODED_ORDINAL; ++i) {
        memoized[i] = -1;
    }

    printf("%d\n\n", getFibonacciNumberByOrdinal(memoized, HARDCODED_ORDINAL));

    delete[] memoized;
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}
