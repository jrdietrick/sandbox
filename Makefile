LOAD_LOCATION = 0x00400000

CFLAGS   += -m32 -Wall -fno-builtin -fno-stack-protector -nostdlib -g
ASFLAGS  += -f elf -g -F dwarf -DLOAD_LOCATION=$(LOAD_LOCATION)
LDFLAGS  += -m32 -nostdlib -static -Ttext=$(LOAD_LOCATION)
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
