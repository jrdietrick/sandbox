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

kernel: boot32.o boot16.o program0
	$(CC) $(LDFLAGS) -Ttext=$(LOAD_LOCATION) boot32.o -o $@
	cat boot16.o > disk_image
	dd if=/dev/zero bs=512 count=16 >> disk_image
	objcopy -O binary --only-section=.text kernel kernel.o.text
	dd if=kernel.o.text of=disk_image bs=512 seek=1 conv=notrunc
	dd if=/dev/zero bs=512 count=1 seek=17 >> disk_image
	objcopy -O binary --only-section=.text program0 program0.o.text
	dd if=program0.o.text of=disk_image bs=512 seek=17 conv=notrunc
	rm *.o.text

boot32.o: boot32.asm exceptions.asm vga.asm vm.asm syscalls.asm pic.asm keyboard.asm
	$(AS) $(ASFLAGS) -DLOAD_LOCATION=$(LOAD_LOCATION) -o $@ $<

boot16.o: boot16.asm
	$(AS) -DLOAD_LOCATION=$(LOAD_LOCATION) -o $@ $<

program0: program0.o
	$(CC) $(LDFLAGS) -Ttext=0x02000000 $< -o $@

program0.o: program0.asm userlib.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f *.o *.o.text kernel disk_image program0
