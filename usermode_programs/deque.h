#ifndef __DEQUE_H__
#define __DEQUE_H__

#define DEFAULT_SLAB_COUNT 32
#define EACH_SLAB_DEFAULT_SIZE 4

typedef class Slab {

public:
    void** data_array_;

    Slab (
        int size
        );

    ~Slab (
        );

    int getSize (
        );

private:
    int size_;
} Slab;

typedef class Deque {

public:
    Deque (
        );

    ~Deque (
        );

    bool empty (
        );

    void pushLeft (
        void* thing
        );

    void* popLeft (
        );

    void pushRight (
        void* thing
        );

    void* popRight (
        );

private:
    int* index_table_;
    Slab** slab_table_;
    int left_index_;
    int right_index_;
    int leftmost_slab_;
    int rightmost_slab_;
    int slab_count_;

    int currentLeftSlabLeftBound (
        );

    int currentLeftSlabRightBound (
        );

    int currentRightSlabLeftBound (
        );

    int currentRightSlabRightBound (
        );

    void leftEndHopLeft (
        );

    void leftEndHopRight (
        );

    void rightEndHopLeft (
        );

    void rightEndHopRight (
        );

    void expandIfNeeded (
        );

    void expandInternal (
        );
} Deque;

#endif