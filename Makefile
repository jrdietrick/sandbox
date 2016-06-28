LOAD_LOCATION = 0x00008000

CFLAGS   += -m32 -Wall -fno-builtin -fno-stack-protector -nostdlib -g
ASFLAGS  += -f elf -g -F dwarf
LDFLAGS  += -m32 -nostdlib -static
CPPFLAGS += -m32 -nostdinc -g

CC = gcc
AS = nasm

PROGRAMS_DIR = usermode_programs

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
#        | Usermode program (if exists)                   |
#        | 16 kilobytes                                   |
# 25088B +------------------------------------------------+

disk_image: boot16.bin kernel.o.text fs_image
	cat boot16.bin > $@
	dd if=/dev/zero bs=512 count=16 status=none >> $@
	dd if=kernel.o.text of=$@ bs=512 seek=1 count=16 conv=notrunc status=none
	dd if=$(PROGRAMS_DIR)/fs_image of=$@ bs=512 seek=17 count=32 conv=notrunc status=none

fs_image:
	$(MAKE) -C $(PROGRAMS_DIR)

kernel.o.text: kernel.o
	objcopy -O binary --only-section=.text $< $@
	test `wc -c < $@` -le 8192 || (echo '$@ exceeds allowable size!'; exit 1)

kernel.o: kernel.bin
	$(CC) $(LDFLAGS) -Ttext=$(LOAD_LOCATION) -o $@ $<

kernel.bin: $(filter-out boot16.asm,$(wildcard *.asm))
	$(AS) $(ASFLAGS) -DLOAD_LOCATION=$(LOAD_LOCATION) -o $@ $<

# The MBR code is compiled raw (not an ELF),
# and as such we get no debugging symbols
boot16.bin: boot16.asm
	$(AS) -DLOAD_LOCATION=$(LOAD_LOCATION) -o $@ $<

clean:
	rm -f *.bin *.o *.o.text kernel disk_image
	$(MAKE) -C $(PROGRAMS_DIR) clean
