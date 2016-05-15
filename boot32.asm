%define FLAG(x) (1 << x)
%define DISABLE_FLAG(x) (~x)

%define CR0_PROTECTED_MODE FLAG(0)

%define KERNEL_TSS          0x0008
%define KERNEL_CODE_SEGMENT 0x0010
%define KERNEL_DATA_SEGMENT 0x0018
%define USER_CODE_SEGMENT   0x0023
%define USER_DATA_SEGMENT   0x002b

%define GDT_DESCRIPTOR_PRESENT FLAG(47)
%define TSS_DESCRIPTOR_TYPE (0x9 << 40)
%define SEGMENT_DESCRIPTOR_BASE(x) (((x & 0x00ffffff) << 16) | ((x & 0xff000000) << 56))
%define SEGMENT_DESCRIPTOR_LIMIT(x) (((x & 0xf0000) << 32) | (x & 0x0ffff))
%define SEGMENT_DESCRIPTOR_DPL(x) ((x & 0x3) << 45)
%define SEGMENT_DESCRIPTOR_TYPE_CODE (0x1a << 40)
%define SEGMENT_DESCRIPTOR_TYPE_DATA (0x12 << 40)
%define SEGMENT_DESCRIPTOR_PRESENT FLAG(47)
%define SEGMENT_DESCRIPTOR_32BIT FLAG(54)
%define SEGMENT_DESCRIPTOR_GRANULARITY_4KB FLAG(55)

%define FLAT_4GB_SEGMENT SEGMENT_DESCRIPTOR_BASE(0x0000) | SEGMENT_DESCRIPTOR_LIMIT(0xfffff) | SEGMENT_DESCRIPTOR_GRANULARITY_4KB | SEGMENT_DESCRIPTOR_32BIT

%define VGA_START 0x000b8000
%define USER_LOAD_LOCATION 0x02000000
%define USER_STACK_LOCATION 0x02400000

global _start

; We lied a little with the name of this file -- at this point we are
; still in 16-bit real mode. But we had to get out of that
; claustrophobic MBR sector. Just need to set up segmentation and then
; we can be on our way...
use16

start:
_start:
    cli

    ; Populate linear addresses for some structures
    ; we can't compute at compile time
    mov dword [gdt_desc + 2], gdt
    mov dword [idt_desc + 2], idt

    ; Turn on protected mode
    mov eax, cr0
    or eax, CR0_PROTECTED_MODE
    mov cr0, eax

    ; Switch to our own segments (load the GDT)
    lgdt [gdt_desc]
    jmp KERNEL_CODE_SEGMENT:start32

; Now we're really in 32-bit protected mode
use32

start32:
    ; Set stack to a known location
    mov esp, LOAD_LOCATION
    mov ecx, KERNEL_DATA_SEGMENT
    mov ss, cx
    mov ds, cx
    xor ecx, ecx
    mov es, cx
    mov fs, cx
    mov gs, cx

    ; Fill in the TSS entry in the GDT
    mov ecx, tss.end - tss - 1
    mov word [gdt.tss_entry], cx
    mov ecx, tss
    mov word [gdt.tss_entry + 2], cx
    shr ecx, 16
    mov byte [gdt.tss_entry + 4], cl
    shr ecx, 8
    mov byte [gdt.tss_entry + 7], cl

    ; ... and some statics in the TSS itself
    mov dword [tss + 4], LOAD_LOCATION ; ESP0
    mov dword [tss + 8], KERNEL_DATA_SEGMENT ; SS0
    mov cx, KERNEL_TSS
    ltr cx

setup_idt:
    mov ecx, 0

.loop:
    push dword 0 ; ring 0
    push ecx
    call fill_idt
    pop ecx
    add esp, 4

    inc ecx
    cmp ecx, 48
    jl .loop

    ; System call gate
    push dword 3 ; ring 3
    push dword 128
    call fill_idt
    add esp, 8

    ; Load our interrupt vectors
    lidt [idt_desc]

    sti

    call basic_paging_setup

    ; Clear the screen and print "OK"
    call disable_cursor
    call clear_screen
    mov esi, string_ok
    call println

    ; Print an empty line
    push dword 0
    mov esi, esp
    call println
    add esp, 4

    call print_ascii_table

    push dword 0
    call load_program
    add esp, 4

    ; call initialize_8259

    ; ; Print an empty line
    ; push dword 0
    ; mov esi, esp
    ; call println
    ; add esp, 4

halt:
    hlt
    jmp halt

    call assert_false
assert_false:
    ; If we end up here, something very
    ; unexpected happened. Fire off a debug
    ; exception, which we will never return
    ; from.
    int 0x1

load_program:
    ; Calculate the starting address of
    ; the program we're loading on our
    ; "filesystem"
    mov esi, 0xc000
    mov ecx, [esp + 0x04]
    shl ecx, 9
    add esi, ecx
    mov edi, USER_LOAD_LOCATION ; load program at 32MB
    mov ecx, 0x80 ; move 128 dwords (one sector)
    rep movsd

    cli
    push dword USER_DATA_SEGMENT
    push dword USER_STACK_LOCATION
    pushfd
    or dword [esp], 0x200 ; re-enable interrupts when we reach usermode
    push dword USER_CODE_SEGMENT
    push dword USER_LOAD_LOCATION
    mov ax, USER_DATA_SEGMENT
    mov ds, ax
    iret

fill_idt:
    push ebp
    mov ebp, esp
    push ebx

    ; Get the ring level from the stack
    mov edx, [ebp + 12]
    shl dx, 13
    or dx, 0x8f00

    ; Calculate the address of our IDT descriptor
    mov ebx, idt
    mov eax, [ebp + 8]
    mov ecx, eax
    imul ecx, 8
    add ebx, ecx

    ; Fetch the entry point from the jump table
    mov eax, [exception_jump_table + (4 * eax)]

    ; Don't fill if there is no pointer
    cmp eax, 0
    jz .skip

    mov word [ebx + 2], KERNEL_CODE_SEGMENT
    mov [ebx], ax
    shr eax, 16
    mov [ebx + 6], ax
    mov word [ebx + 4], dx

.skip:
    pop ebx
    pop ebp
    ret

align 16, db 0

    dw 0 ; padding
gdt_desc:
    dw gdt.end - gdt - 1
    dd 0 ; will be filled in at start

    dw 0 ; padding
idt_desc:
    dw idt.end - idt - 1
    dd 0 ; will be filled in at start

align 8, db 0

gdt: ; GDT should be 8-byte aligned
    dq 0
.tss_entry:
    dq GDT_DESCRIPTOR_PRESENT | TSS_DESCRIPTOR_TYPE ; TSS entry, will be filled in further at start
    ; kernel code segment
    dq FLAT_4GB_SEGMENT | SEGMENT_DESCRIPTOR_DPL(0) | SEGMENT_DESCRIPTOR_TYPE_CODE | SEGMENT_DESCRIPTOR_PRESENT
    ; kernel data segment
    dq FLAT_4GB_SEGMENT | SEGMENT_DESCRIPTOR_DPL(0) | SEGMENT_DESCRIPTOR_TYPE_DATA | SEGMENT_DESCRIPTOR_PRESENT
    ; user code segment
    dq FLAT_4GB_SEGMENT | SEGMENT_DESCRIPTOR_DPL(3) | SEGMENT_DESCRIPTOR_TYPE_CODE | SEGMENT_DESCRIPTOR_PRESENT
    ; user data segment
    dq FLAT_4GB_SEGMENT | SEGMENT_DESCRIPTOR_DPL(3) | SEGMENT_DESCRIPTOR_TYPE_DATA | SEGMENT_DESCRIPTOR_PRESENT
.end:

align 8, db 0

tss:
    times 104 db 0
.end:

align 8, db 0

idt:
    times 129 dq 0
.end:

%include "vga.asm"
%include "exceptions.asm"
%include "syscalls.asm"
%include "vm.asm"
%include "pic.asm"
%include "keyboard.asm"

align 16, db 0

string_ok: db 'OK', 0
string_exception: db 'EXCEPTION OCCURRED', 0
string_double_fault: db 'DOUBLE FAULT', 0
string_general_protection_fault: db 'GENERAL PROTECTION FAULT', 0
string_page_fault: db 'PAGE FAULT', 0
string_system_call: db 'SYSTEM CALL', 0
string_pic_interrupt: db 'INTERRUPT', 0

align 16, db 0
