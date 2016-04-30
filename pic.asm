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
    mov dx, MASTER_PIC_COMMAND
    mov ax, 0x11
    out dx, ax
    mov dx, MASTER_PIC_DATA
    mov ax, 0x20
    out dx, ax
    mov ax, 0x04
    out dx, ax
    mov ax, 0x01
    out dx, ax
    mov dx, SLAVE_PIC_COMMAND
    mov ax, 0x11
    out dx, ax
    mov dx, SLAVE_PIC_DATA
    mov ax, 0x28
    out dx, ax
    mov ax, 0x02
    out dx, ax
    mov ax, 0x01
    out dx, ax

    ; Disable all IRQs
    mov ecx, 0
.loop:
    push ecx
    call disable_irq
    pop ecx
    inc ecx
    cmp ecx, 16
    jl .loop

    ret
