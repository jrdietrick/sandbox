align 16, db 0

db 'vga.asm', 0

align 16, db 0

%macro print_space 0
    mov al, 0x20 ; ' '
    call putc
%endmacro

%macro print_newline 0
    mov al, 0x0a ; '\n'
    call putc
%endmacro

%macro print_register 2
    push register_names.%1
    call print_register_name
    add esp, 4
    mov eax, [ebp + %2]
    push eax
    call print_hex_value_32
    add esp, 4
%endmacro

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
    cmp al, 0x0a
    je .newline

    ; Calculate memory address
    xor ecx, ecx
    mov ecx, dword [cursor_y]
    imul ecx, 80
    add ecx, dword [cursor_x]
    shl ecx, 1

    ; AL contains the byte to write
    mov ah, 0x07
    mov word [VGA_START + ecx], ax

    ; Increment
    add byte [cursor_x], 1
    cmp byte [cursor_x], 80
    jl .done
.newline:
    mov byte [cursor_x], 0
    add byte [cursor_y], 1
    cmp byte [cursor_y], 25
    jl .done
    call clear_screen
.done:
    ret

puts:
.loop:
    lodsb
    cmp al, 0
    je .done
    call putc
    jmp .loop
.done:
    ret

println:
    call puts
    mov al, 0x0a ; '\n'
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
    print_newline
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

print_exception_stack:
    push register_names.eip
    call print_register_name
    add esp, 4
    mov ecx, [esp + 0x04]
    mov eax, [ecx + 0x04]
    push eax
    call print_hex_value_32
    add esp, 4
    mov al, 0x0a ; '\n'
    call putc
    ret

register_names:
.eax: db 'EAX', 0
.ebx: db 'EBX', 0
.ecx: db 'ECX', 0
.edx: db 'EDX', 0
.esi: db 'ESI', 0
.edi: db 'EDI', 0
.ebp: db 'EBP', 0
.esp: db 'ESP', 0
.eip: db 'EIP', 0

print_register_name:
    push esi
    mov esi, [esp + 8]
    call puts
    mov al, 0x3d ; '='
    call putc
    pop esi
    ret

print_registers:
    ; We assume we're called right after a pushad,
    ; so all the registers are on the stack
    ; TODO: Is that safe? Is `pushad` hardware-
    ; independent?
    push ebp
    mov ebp, esp

    print_register eax, 0x24
    print_space
    print_register ebx, 0x18
    print_space
    print_register ecx, 0x20
    print_space
    print_register edx, 0x1c
    print_newline

    print_register esi, 0x0c
    print_space
    print_register edi, 0x08
    print_space
    print_register ebp, 0x10
    print_space
    print_register esp, 0x14
    print_newline

    pop ebp
    ret

cursor_x: dd 0
cursor_y: dd 0
