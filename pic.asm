align 16, db 0

db 'apic.asm', 0

align 16, db 0

%define MASTER_PIC_COMMAND 0x20
%define MASTER_PIC_DATA (MASTER_PIC_COMMAND + 1)
%define SLAVE_PIC_COMMAND 0xa0
%define SLAVE_PIC_DATA (SLAVE_PIC_COMMAND + 1)

irq_bitmask:
    mov ecx, 1
.shift:
    cmp eax, 0
    je .done
    shl ecx, 1
    dec eax
    jmp .shift
.done:
    ret

enable_irq:
    mov eax, [esp + 0x04]
    mov dx, MASTER_PIC_DATA
    cmp eax, 7
    jle .master
    mov dx, SLAVE_PIC_DATA
    add eax, -8
.master:
    ; Make ECX == 1 << EAX
    call irq_bitmask
    not ecx
    in al, dx
    and al, cl
    out dx, al
    ret

disable_irq:
    mov eax, [esp + 0x04]
    mov dx, MASTER_PIC_DATA
    cmp eax, 7
    jle .master
    mov dx, SLAVE_PIC_DATA
    add eax, -8
.master:
    ; Make ECX == 1 << EAX
    call irq_bitmask
    in al, dx
    or al, cl
    out dx, al
    ret

initialize_8259:
    push ebx

    ; Save existing masks
    in al, MASTER_PIC_DATA
    mov bl, al
    in al, SLAVE_PIC_DATA
    mov cl, al

    mov al, 0x11
    out MASTER_PIC_COMMAND, al
    mov al, 0x20
    out MASTER_PIC_DATA, al
    mov al, 0x04
    out MASTER_PIC_DATA, al
    mov al, 0x01
    out MASTER_PIC_DATA, al
    mov al, 0x11
    out SLAVE_PIC_COMMAND, al
    mov al, 0x28
    out SLAVE_PIC_DATA, al
    mov al, 0x02
    out SLAVE_PIC_DATA, al
    mov al, 0x01
    out SLAVE_PIC_DATA, al

    ; Restore masks
    mov al, bl
    out MASTER_PIC_DATA, al
    mov al, cl
    out SLAVE_PIC_DATA, al

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
