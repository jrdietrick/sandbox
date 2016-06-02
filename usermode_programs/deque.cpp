#include "userlib"
#include "deque.h"


Slab::Slab (
    int size
    ) : size_(size)
{
    data_array_ = new void*[size];
    assert(data_array_ != NULL);
}

Slab::~Slab (
    )
{
    delete[] data_array_;
}

int Slab::getSize (
    )
{
    return size_;
}

Deque::Deque (
    ) : left_index_(0), right_index_(0),
        leftmost_slab_(DEFAULT_SLAB_COUNT / 2), rightmost_slab_(DEFAULT_SLAB_COUNT / 2),
        slab_count_(DEFAULT_SLAB_COUNT)
{
    index_table_ = new int[DEFAULT_SLAB_COUNT];
    slab_table_ = new Slab*[DEFAULT_SLAB_COUNT];

    for (int i = 0; i < DEFAULT_SLAB_COUNT; i++) {
        slab_table_[i] = nullptr;
        index_table_[i] = INT_MIN;
    }

    slab_table_[DEFAULT_SLAB_COUNT / 2 - 1] = new Slab(EACH_SLAB_DEFAULT_SIZE);
    slab_table_[DEFAULT_SLAB_COUNT / 2] = new Slab(EACH_SLAB_DEFAULT_SIZE);
    index_table_[DEFAULT_SLAB_COUNT / 2 - 1] = 0 - slab_table_[DEFAULT_SLAB_COUNT / 2 - 1]->getSize();
    index_table_[DEFAULT_SLAB_COUNT / 2] = 0;
    leftmost_slab_ = DEFAULT_SLAB_COUNT / 2;
    rightmost_slab_ = leftmost_slab_;
}

Deque::~Deque (
    )
{
    for (int i = 0; i < slab_count_; i++) {
        if (slab_table_[i] != nullptr) {
            delete slab_table_[i];
        }
    }

    delete[] slab_table_;
    delete[] index_table_;
}

int Deque::currentLeftSlabLeftBound (
    )
{
    return index_table_[leftmost_slab_];
}

int Deque::currentLeftSlabRightBound (
    )
{
    return index_table_[leftmost_slab_] + slab_table_[leftmost_slab_]->getSize();
}

int Deque::currentRightSlabLeftBound (
    )
{
    return index_table_[rightmost_slab_];
}

int Deque::currentRightSlabRightBound (
    )
{
    return index_table_[rightmost_slab_] + slab_table_[rightmost_slab_]->getSize();
}

bool Deque::empty (
    )
{
    return left_index_ == right_index_;
}

void Deque::leftEndHopLeft (
    )
{
    assert(slab_table_[leftmost_slab_ - 1] != NULL);
    assert(index_table_[leftmost_slab_ - 1] != INT_MIN);
    leftmost_slab_--;
}

void Deque::leftEndHopRight (
    )
{
    assert(slab_table_[leftmost_slab_ + 1] != NULL);
    assert(index_table_[leftmost_slab_ + 1] != INT_MIN);
    leftmost_slab_++;
}

void Deque::rightEndHopLeft (
    )
{
    assert(slab_table_[rightmost_slab_ - 1] != NULL);
    assert(index_table_[rightmost_slab_ - 1] != INT_MIN);
    rightmost_slab_--;
}

void Deque::rightEndHopRight (
    )
{
    assert(slab_table_[rightmost_slab_ + 1] != NULL);
    assert(index_table_[rightmost_slab_ + 1] != INT_MIN);
    rightmost_slab_++;
}

void Deque::expandIfNeeded (
    )
{
    // If the left cursor is up against the end,
    // add a new slab on the left if needed
    if (left_index_ == currentLeftSlabLeftBound()) {
        if (leftmost_slab_ == 0) {
            // We need to expand the whole management array first
            expandInternal();
        }
        if (slab_table_[leftmost_slab_ - 1] == nullptr) {
            Slab* new_slab = new Slab(EACH_SLAB_DEFAULT_SIZE);
            slab_table_[leftmost_slab_ - 1] = new_slab;
            index_table_[leftmost_slab_ - 1] = index_table_[leftmost_slab_] - new_slab->getSize();
        }
    }

    // If the right cursor is off the right end,
    // add a new slab on the right if needed
    if (right_index_ == currentRightSlabRightBound()) {
        if (rightmost_slab_ == slab_count_ - 1) {
            // We need to expand the whole management array first
            expandInternal();
        }
        if (slab_table_[rightmost_slab_ + 1] == nullptr) {
            Slab* new_slab = new Slab(EACH_SLAB_DEFAULT_SIZE);
            slab_table_[rightmost_slab_ + 1] = new_slab;
            index_table_[rightmost_slab_ + 1] = index_table_[rightmost_slab_] + new_slab->getSize();
        }
    }
}

void Deque::expandInternal (
    )
{
    int next_size = slab_count_ * 3;
    int* new_index_table = new int[next_size];
    Slab** new_slab_table = new Slab*[next_size];

    for (int i = 0; i < slab_count_; i++) {
        new_slab_table[i] = nullptr;
        new_index_table[i] = INT_MIN;
    }

    for (int i = 0; i < slab_count_; i++) {
        new_slab_table[slab_count_ + i] = slab_table_[i];
        new_index_table[slab_count_ + i] = index_table_[i];
    }

    for (int i = slab_count_ * 2; i < next_size; i++) {
        new_slab_table[i] = nullptr;
        new_index_table[i] = INT_MIN;
    }

    leftmost_slab_ += slab_count_;
    rightmost_slab_ += slab_count_;

    delete[] index_table_;
    index_table_ = new_index_table;
    delete[] slab_table_;
    slab_table_ = new_slab_table;

    slab_count_ = next_size;
}

void Deque::pushLeft (
    void* thing
    )
{
    // We want to insert at left_index - 1
    left_index_--;

    if (left_index_ < currentLeftSlabLeftBound()) {
        leftEndHopLeft();
    }

    Slab* current_left_slab = slab_table_[leftmost_slab_];
    int index_in_slab = left_index_ - index_table_[leftmost_slab_];
    current_left_slab->data_array_[index_in_slab] = thing;

    expandIfNeeded();
}

void* Deque::popLeft (
    )
{
    if (empty()) {
        return nullptr;
    }

    int index_in_slab = left_index_ - index_table_[leftmost_slab_];
    void* thing = slab_table_[leftmost_slab_]->data_array_[index_in_slab];

    left_index_++;

    if (left_index_ >= currentLeftSlabRightBound()) {
        leftEndHopRight();
    }

    return thing;
}

void Deque::pushRight (
    void* thing
    )
{
    // We want to insert at right_index
    int index_in_slab = right_index_ - index_table_[rightmost_slab_];
    slab_table_[rightmost_slab_]->data_array_[index_in_slab] = thing;

    // Increment index
    right_index_++;

    expandIfNeeded();

    if (right_index_ >= currentRightSlabRightBound()) {
        rightEndHopRight();
    }
}

void* Deque::popRight (
    )
{
    if (empty()) {
        return nullptr;
    }

    right_index_--;

    if (right_index_ < currentRightSlabLeftBound()) {
        rightEndHopLeft();
    }

    int index_in_slab = right_index_ - index_table_[rightmost_slab_];
    void* thing = slab_table_[rightmost_slab_]->data_array_[index_in_slab];

    return thing;
}

int main (
    )
{
    Deque myDeque;
    char itoa_buffer[33];

    for (int i = 0; i < 128; i++) {
        myDeque.pushRight(new int[1]{i});
    }

    while (!myDeque.empty()) {
        int* thing = static_cast<int*>(myDeque.popLeft());
        itoa(*thing, itoa_buffer, 10);
        puts(itoa_buffer);
        puts("\n");
        delete thing;
    }
    puts("\n\n");
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}
