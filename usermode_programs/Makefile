CFLAGS  += -m32 -Wall -fno-builtin -fno-stack-protector -fno-exceptions -nostdlib -g
ASFLAGS += -f elf -g -F dwarf
LDFLAGS += -melf_i386

CC = gcc
CXX = g++ -std=c++11
AS = nasm

SRCS = avl_tree.cpp \
	   hashtable.cpp \
	   deque.cpp \
	   towers_of_hanoi.cpp \
	   mergesort.cpp \
	   itoa.c \
	   heapsort.cpp \
	   quicksort.cpp \
	   malloc_test.c \
	   program0.asm \
	   program1.c \
	   merge_two_sorted_arrays_in_place.cpp

ELFS_IN_SRCS_ORDER = $(patsubst %.asm,%.o,$(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(SRCS))))

ASM_ELFS = $(patsubst %.asm,%.o,$(filter %.asm,$(SRCS)))
ASM_BINS = $(patsubst %.asm,%.bin,$(filter %.asm,$(SRCS)))

C_ELFS = $(patsubst %.c,%.o,$(filter %.c,$(SRCS)))
C_BINS = $(patsubst %.c,%.bin,$(filter %.c,$(SRCS)))

CXX_ELFS = $(patsubst %.cpp,%.o,$(filter %.cpp,$(SRCS)))
CXX_BINS = $(patsubst %.cpp,%.bin,$(filter %.cpp,$(SRCS)))

all: fs_image $(ASM_BINS) $(C_BINS) $(CXX_BINS)

fs_image: $(ELFS_IN_SRCS_ORDER) Makefile
	bash assemble_fs_image.sh $@ $(ELFS_IN_SRCS_ORDER)

%.o: %.bin
	cp $< $@
	strip -d $@
	test `wc -c < $@` -le 16384 || (echo '$@ exceeds allowable size!'; exit 1)

$(ASM_BINS):%.bin: %.asm userlib.asm
	$(AS) $(ASFLAGS) -o $@ $<

$(C_BINS):%.bin: %.c userlib.h userlib.o
	$(CC) -c $(CFLAGS) -o $@.tmp $<
	$(LD) --relocatable $(LDFLAGS) -o $@ userlib.o $@.tmp
	rm $@.tmp

$(CXX_BINS):%.bin: %.cpp userlib.h userlib.o
	$(CXX) -c $(CFLAGS) -o $@.tmp $<
	$(LD) --relocatable $(LDFLAGS) -o $@ userlib.o $@.tmp
	rm $@.tmp

userlib.o: userlib.asm allocator.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f *.o *.tmp $(CXX_BINS) $(C_BINS) $(ASM_BINS) fs_image
