#include "userlib"
#include "towers_of_hanoi.h"


Disk::Disk (
    int radius
    ) : radius_(radius), disk_below_(nullptr)
{
}

Spindle::Spindle (
    char* name
    ) : top_(nullptr), name_(name)
{
}

bool Spindle::empty (
    )
{
    return top_ ? false : true;
}

Disk* Spindle::pop (
    )
{
    assert(top_ != nullptr);
    Disk* just_popped = top_;
    top_ = just_popped->disk_below_;
    just_popped->disk_below_ = nullptr;
    return just_popped;
}

void Spindle::push (
    Disk* disk
    )
{
    assert(disk->disk_below_ == nullptr);
    disk->disk_below_ = top_;
    top_ = disk;
    if (disk->disk_below_) {
        assert(disk->radius_ < disk->disk_below_->radius_);
    }
}

char* Spindle::getName (
    )
{
    return name_;
}

void move (
    Spindle* from,
    Spindle* to,
    int disk_count,
    Spindle* swap
    )
{
    Disk* disk_in_hand;

    if (disk_count == 1) {
        disk_in_hand = from->pop();
        to->push(disk_in_hand);
        //printf("Disk of radius %d from %s -> %s\n",
        //       disk_in_hand->radius_,
        //       from->getName(),
        //       to->getName());
        return;
    }

    // For anything above two, move all disks
    // above us, using the destination (to) as
    // swap space...
    move(from, swap, disk_count - 1, to);

    // Move us...
    move(from, to, 1, nullptr);

    // Now move everything from swap to the
    // destination, using "from" as swap
    move(swap, to, disk_count - 1, from);
}

int main (
    )
{
    Disk* disk8 = new Disk(8);
    Disk* disk7 = new Disk(7);
    Disk* disk6 = new Disk(6);
    Disk* disk5 = new Disk(5);
    Disk* disk4 = new Disk(4);
    Disk* disk3 = new Disk(3);
    Disk* disk2 = new Disk(2);
    Disk* disk1 = new Disk(1);

    Spindle* spin0 = new Spindle("spindle 0");
    Spindle* spin1 = new Spindle("spindle 1");
    Spindle* spin2 = new Spindle("spindle 2");

    spin0->push(disk8);
    spin0->push(disk7);
    spin0->push(disk6);
    spin0->push(disk5);
    spin0->push(disk4);
    spin0->push(disk3);
    spin0->push(disk2);
    spin0->push(disk1);

    move(spin0, spin1, 5, spin2);

    delete spin2;
    delete spin1;
    delete spin0;

    delete disk1;
    delete disk2;
    delete disk3;
    delete disk4;
    delete disk5;
    delete disk6;
    delete disk7;
    delete disk8;

    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}
