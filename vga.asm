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
    mov byte [cursor_x], 0
    mov byte [cursor_y], 0
    ret

putc:
    cmp al, 0xa
    je .newline

    ; Calculate memory address
    xor ecx, ecx
    mov cl, [cursor_y]
    imul ecx, 80
    add cl, [cursor_x]
    imul ecx, 2

    ; AL contains the byte to write
    mov ah, 0x07
    mov word [VGA_START + ecx], ax

    ; Increment
    add byte [cursor_x], 1
    cmp byte [cursor_x], 80
    jne .done
.newline:
    mov byte [cursor_x], 0
    add byte [cursor_y], 1
    cmp byte [cursor_y], 25
    jne .done
    call clear_screen
.done:
    ret

println:
.loop:
    lodsb
    cmp al, 0
    je .done
    call putc
    jmp .loop

.done:
    mov al, 0xa
    call putc
    ret

cursor_x: db 0
cursor_y: db 0