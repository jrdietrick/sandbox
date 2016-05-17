CFLAGS  += -m32 -Wall -fno-builtin -fno-stack-protector -nostdlib -g
ASFLAGS += -f elf -g -F dwarf
LDFLAGS += -melf_i386

CC = gcc
AS = nasm

SRCS = program0.asm \
	   program1.c \
	   merge_two_sorted_arrays_in_place.c

ASM_ELFS = $(patsubst %.asm,%.o,$(filter %.asm,$(SRCS)))
ASM_BINS = $(patsubst %.asm,%.bin,$(filter %.asm,$(SRCS)))

C_ELFS = $(patsubst %.c,%.o,$(filter %.c,$(SRCS)))
C_BINS = $(patsubst %.c,%.bin,$(filter %.c,$(SRCS)))

all: fs_image $(ASM_ELFS) $(ASM_BINS) $(C_ELFS) $(C_BINS)

fs_image: $(ASM_ELFS) $(C_ELFS)
	bash assemble_fs_image.sh $@ $(ASM_ELFS) $(C_ELFS)

%.o: %.bin
	cp $< $@
	strip -d $@
	test `wc -c < $@` -le 4096 || (echo '$@ exceeds allowable size!'; exit 1)

$(ASM_BINS):%.bin: %.asm userlib.asm
	$(AS) $(ASFLAGS) -o $@ $<

$(C_BINS):%.bin: %.c userlib.h userlib.o
	$(CC) -c $(CFLAGS) -o $@.tmp $<
	$(LD) --relocatable $(LDFLAGS) -o $@ userlib.o $@.tmp
	rm $@.tmp

userlib.o: userlib.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f *.o *.tmp $(C_BINS) $(ASM_BINS) fs_image
