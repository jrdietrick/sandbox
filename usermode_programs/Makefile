ASFLAGS  += -f elf -g -F dwarf
LDFLAGS  += -m32 -nostdlib -static

CC = gcc
AS = nasm

SRCS = program0.asm

ELFS = $(patsubst %.asm,%.o,$(SRCS))
RAW_BINS = $(patsubst %.asm,%.o.text,$(SRCS))

all: fs_image $(ELFS)

fs_image: $(RAW_BINS)
	bash assemble_fs_image.sh $@ $(RAW_BINS)

%.o.text: %.o
	objcopy -O binary --only-section=.text $< $@

%.o: %.bin
	$(CC) $(LDFLAGS) -Ttext=0x02000000 $< -o $@

%.bin: %.asm userlib.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f $(RAW_BINS) $(ELFS) *.bin fs_image
