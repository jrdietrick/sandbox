ASFLAGS  += -f elf -g -F dwarf
LDFLAGS  += -m32 -nostdlib -static

CC = gcc
AS = nasm

SRCS = program0.asm

ELFS = $(patsubst %.asm,%.o,$(SRCS))
BINS = $(patsubst %.asm,%.bin,$(SRCS))

all: fs_image $(ELFS) $(BINS)

fs_image: $(ELFS)
	bash assemble_fs_image.sh $@ $(ELFS)

%.o: %.bin
	cp $< $@
	strip -d $@
	test `wc -c < $@` -le 4096 || (echo '$@ exceeds allowable size!'; exit 1)

%.bin: %.asm userlib.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f $(ELFS) $(BINS) fs_image
