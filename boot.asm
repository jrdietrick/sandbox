%define MULTIBOOT_HEADER_MAGIC 0x1BADB002
%define MULTIBOOT_HEADER_FLAGS 0x00000003

%define LOAD_LOCATION 0x00400000

%define KERNEL_CODE_SEGMENT 0x0008
%define KERNEL_DATA_SEGMENT 0x0010

extern c_entry

global start, _start

use32

align 32, db 0

multiboot_header:
    dd MULTIBOOT_HEADER_MAGIC
    dd MULTIBOOT_HEADER_FLAGS
    dd -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
    ; dd multiboot_header
    ; dd entry
    ; dd 0x0000
    ; dd 0x0000
    ; dd entry

align 16, db 0

start:
_start:
    cli
    mov dword [gdt_desc + 2], gdt
    lgdt [gdt_desc]
    jmp KERNEL_CODE_SEGMENT:keep_going

keep_going:
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
    dq 0 ; will be filled in at start

align 32, db 0