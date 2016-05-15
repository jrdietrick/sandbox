LOAD_LOCATION = 0x00008000

CFLAGS   += -m32 -Wall -fno-builtin -fno-stack-protector -nostdlib -g
ASFLAGS  += -f elf -g -F dwarf
LDFLAGS  += -m32 -nostdlib -static
CPPFLAGS += -m32 -nostdinc -g

CC = gcc
AS = nasm

# Map of disk_image
#
#     0B +------------------------------------------------+
#        | MBR sector (boot16.o)                          |
#        | 512 bytes                                      |
#   512B +------------------------------------------------+
#        | Kernel (boot32.asm and dependencies)           |
#        | .text only, extracted from `kernel` ELF        |
#        \                                                /
#        /                                                \
#        \                                                /
#        /                                                \
#        | 8 kilobytes maximum (zero-padded if smaller)   |
#        |                                                |
#  8704B +------------------------------------------------+
#        | Usermode program #0 (if exists)                |
#        | 512 bytes                                      |
#  9216B +------------------------------------------------+
#        | Usermode program #1 (if exists)                |
#        | 512 bytes                                      |
#  9728B +------------------------------------------------+
#        \                                                /
#        / Usermode programs #2-14 (if exist)             \
#        \ 512 bytes each                                 /
#        /                                                \
# 16384B +------------------------------------------------+
#        | Usermode program #15 (if exists)               |
#        | 512 bytes                                      |
# 16896B +------------------------------------------------+

disk_image: boot16.bin kernel.o.text
	cat boot16.bin > disk_image
	dd if=/dev/zero bs=512 count=32 status=none >> disk_image
	dd if=kernel.o.text of=disk_image bs=512 seek=1 conv=notrunc status=none

kernel.o.text: kernel.o
	objcopy -O binary --only-section=.text $< $@

kernel.o: kernel.bin
	$(CC) $(LDFLAGS) -Ttext=$(LOAD_LOCATION) -o $@ $<

kernel.bin: boot32.asm exceptions.asm vga.asm vm.asm syscalls.asm pic.asm keyboard.asm
	$(AS) $(ASFLAGS) -DLOAD_LOCATION=$(LOAD_LOCATION) -o $@ $<

# The MBR code is compiled raw (not an ELF),
# and as such we get no debugging symbols
boot16.bin: boot16.asm
	$(AS) -DLOAD_LOCATION=$(LOAD_LOCATION) -o $@ $<

clean:
	rm -f *.bin *.o *.o.text kernel disk_image
