use32

global _start

start:
_start:
    call print_the_string

    int 0xd

spin:
    jmp spin

string_to_print: db 'this is a string from userspace', 0x0a, 0

strlen:
    xor eax, eax
    mov edx, [esp + 0x04] ; pointer to buffer
.loop:
    cmp byte [edx], 0x00
    je .done
    inc eax
    inc edx
    jmp .loop
.done:
    ret

print_the_string:
    mov eax, string_to_print
    push eax
    call strlen
    add esp, 4

    mov edx, eax ; length of string
    mov eax, 4 ; write
    mov ebx, 1 ; stdout
    mov ecx, string_to_print

    int 0x80

    ret