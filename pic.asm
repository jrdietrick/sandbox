align 16, db 0

db 'apic.asm', 0

align 16, db 0

%define MASTER_PIC_COMMAND 0x20
%define MASTER_PIC_DATA (MASTER_PIC_COMMAND + 1)
%define SLAVE_PIC_COMMAND 0xa0
%define SLAVE_PIC_DATA (SLAVE_PIC_COMMAND + 1)

disable_irq:
    ; TODO
    nop
    ret

initialize_8259:
    push ebx

    ; Save existing masks
    in ax, MASTER_PIC_DATA
    mov bx, ax
    in ax, SLAVE_PIC_DATA
    mov cx, ax

    mov ax, 0x11
    out MASTER_PIC_COMMAND, ax
    mov ax, 0x20
    out MASTER_PIC_DATA, ax
    mov ax, 0x04
    out MASTER_PIC_DATA, ax
    mov ax, 0x01
    out MASTER_PIC_DATA, ax
    mov ax, 0x11
    out SLAVE_PIC_COMMAND, ax
    mov ax, 0x28
    out SLAVE_PIC_DATA, ax
    mov ax, 0x02
    out SLAVE_PIC_DATA, ax
    mov ax, 0x01
    out SLAVE_PIC_DATA, ax

    ; Restore masks
    mov ax, bx
    out MASTER_PIC_DATA, ax
    mov ax, cx
    out SLAVE_PIC_DATA, ax

    ; Disable all IRQs
    mov ecx, 0
.loop:
    push ecx
    call disable_irq
    pop ecx
    inc ecx
    cmp ecx, 16
    jl .loop

    pop ebx
    ret
