#ifndef __TOWERS_OF_HANOI_H__
#define __TOWERS_OF_HANOI_H__

typedef class Disk {

public:
    int radius_;
    Disk* disk_below_;

    Disk (
        int radius
        );
} Disk;

typedef class Spindle {

    Disk* top_;
    char* name_;

public:
    Spindle (
        char* name
        );

    bool empty (
        );

    Disk* pop (
        );

    void push (
        Disk* disk
        );

    char* getName (
        );
} Spindle;

#endif
