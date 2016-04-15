use32

global _start

start:
_start:
    mov dword [0x03000000], 4
    mov eax, 1
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    int 0x80

spin:
    jmp spin
