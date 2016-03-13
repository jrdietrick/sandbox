CFLAGS   += -m32 -Wall -fno-builtin -fno-stack-protector -nostdlib -g
ASFLAGS  += -f elf -g -F dwarf
LDFLAGS  += -m32 -nostdlib -static -Ttext=0x400000
CPPFLAGS += -m32 -nostdinc -g

CC = gcc
AS = nasm

# This generates the list of source files
SRC = $(wildcard *.c)

OBJS  = boot.o
OBJS += $(patsubst %.c,%.o,$(filter %.c,$(SRC)))

kernel: $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $@

boot.o: boot.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f *.o kernel
