ASFLAGS  += -f elf -g -F dwarf
LDFLAGS  += -m32 -nostdlib -static

CC = gcc
AS = nasm

SRCS = program0.asm

OBJS = $(patsubst %.asm,%.o.text,$(SRCS))

fs_image: $(OBJS)
	bash assemble_fs_image.sh $@ $(OBJS)

%.o.text: %.o
	objcopy -O binary --only-section=.text $< $@

%.o: %.bin
	$(CC) $(LDFLAGS) -Ttext=0x02000000 $< -o $@

%.bin: %.asm userlib.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f $(OBJS) *.o *.bin fs_image
