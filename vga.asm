disable_cursor:
    ; Disable the cursor
    xor eax, eax
    xor edx, edx
    mov dx, 0x3cc
    in ax, dx
    or ax, 0x1
    mov dx, 0x3c2
    out dx, ax
    mov ax, 0xa
    mov dx, 0x3d4
    out dx, ax
    mov dx, 0x3d5
    in ax, dx
    or ax, 0x20
    out dx, ax
    ret

clear_screen:
    mov ecx, 0
.loop:
    mov word [VGA_START + ecx], 0x0720
    add ecx, 2
    cmp ecx, 80 * 25
    jne .loop
    ret

print_string:
    mov ecx, VGA_START
    mov eax, 0x0700

.loop:
    lodsb
    cmp al, 0
    je .done
    mov word [ecx], ax
    add ecx, 2
    jmp .loop

.done:
    ret