align 16, db 0

db 'vga.asm', 0

align 16, db 0

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
    cmp ecx, 80 * 25 * 2
    jne .loop
    mov byte [cursor_x], 0
    mov byte [cursor_y], 0
    ret

putc:
    cmp al, 0xa
    je .newline

    ; Calculate memory address
    xor ecx, ecx
    mov ecx, dword [cursor_y]
    imul ecx, 80
    add ecx, dword [cursor_x]
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

print_ascii_table:
    push ebp
    mov ebp, esp

    ; EAX contains the current character, which runs
    ; from 0 to 127, adding a newline every 16
    xor eax, eax

.loop:
    call putc
    inc al
    mov cl, al
    and cl, 0x0f
    jnz .loop
    push eax
    mov al, 0xa
    call putc
    pop eax
    cmp al, 128
    jb .loop

    pop ebp
    ret

print_hex_value_32:
    mov ecx, 8
    jmp print_hex_value_8.common_start

print_hex_value_16:
    mov ecx, 4
    jmp print_hex_value_8.common_start

print_hex_value_8:
    mov ecx, 2

.common_start:
    push ebp
    mov ebp, esp
    mov edx, [ebp + 8]

    push ecx
    mov al, 0x30 ; '0'
    call putc
    mov al, 0x78 ; 'x'
    call putc
    pop ecx

    push edi
    push ecx
    mov edi, esp
    times 2 push dword 0x00000000
.format_loop:
    xor eax, eax
    mov al, dl
    and al, 0x0f
    add al, 0x30
    cmp al, 0x3a
    jl .skip
    add al, 0x27
.skip:
    dec edi
    mov byte [edi], al
    shr edx, 4
    dec ecx
    jnz .format_loop
    mov ecx, [ebp - 8]
.print_loop:
    mov byte al, [edi]
    push ecx
    call putc
    pop ecx
    inc edi
    dec ecx
    jnz .print_loop

    add esp, 12
    pop edi
    pop ebp
    ret

cursor_x: dd 0
cursor_y: dd 0
