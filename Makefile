LOAD_LOCATION = 0x00008000

CFLAGS   += -m32 -Wall -fno-builtin -fno-stack-protector -nostdlib -g
ASFLAGS  += -f elf -g -F dwarf -DLOAD_LOCATION=$(LOAD_LOCATION)
LDFLAGS  += -m32 -nostdlib -static -Ttext=$(LOAD_LOCATION)
CPPFLAGS += -m32 -nostdinc -g

CC = gcc
AS = nasm

# This generates the list of source files
SRC = $(wildcard *.c)

OBJS  = boot32.o
OBJS += $(patsubst %.c,%.o,$(filter %.c,$(SRC)))

kernel: $(OBJS) boot16.o
	$(CC) $(LDFLAGS) $(OBJS) -o $@
	cat boot16.o > disk_image
	dd if=kernel bs=512 skip=8 count=16 >> disk_image
# TODO: We're just relying on the fact that when we make an ELF of
# kernel it seems like our .text always starts at 0x1000. That is
# obviously a terrible idea. Either read the ELF format correctly and
# extract the exact segment (right now we grab symbols and crap after
# it, too), or abandon ELF entirely and find a different way to make
# debug symbols work!

boot32.o: boot32.asm exceptions.asm
	$(AS) $(ASFLAGS) -o $@ $<

boot16.o: boot16.asm
	$(AS) -DLOAD_LOCATION=$(LOAD_LOCATION) -o $@ $<

clean:
	rm -f *.o kernel disk_image
