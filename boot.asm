%define MULTIBOOT_HEADER_MAGIC 0x1BADB002
%define MULTIBOOT_HEADER_FLAGS 0x00000003

%define KERNEL_CODE_SEGMENT 0x0008
%define KERNEL_DATA_SEGMENT 0x0010

extern c_entry

global start, _start

use32

align 32, db 0

; The multiboot header
dd MULTIBOOT_HEADER_MAGIC
dd MULTIBOOT_HEADER_FLAGS
dd -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

align 16, db 0

start:
_start:
    cli
    mov dword [gdt_desc + 2], gdt
    lgdt [gdt_desc]
    jmp KERNEL_CODE_SEGMENT:continue

continue:
    ; Set stack to a known location
    mov esp, LOAD_LOCATION
    mov cx, KERNEL_DATA_SEGMENT
    mov ss, cx
    mov ds, cx
    mov es, cx
    mov fs, cx
    mov gs, cx

    push ebx
    push eax

    call c_entry

halt:
    hlt
    jmp halt

align 16, db 0

gdt:
    dq 0
    dq 0x00CF9A000000FFFF ; kernel stack segment
    dq 0x00CF92000000FFFF ; kernel data segment
gdt_end:

align 16, db 0

gdt_desc:
    dw gdt_end - gdt - 1
    dd 0 ; will be filled in at start

align 16, db 0