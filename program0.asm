use32

global _start

start:
_start:
    mov eax, 1
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    push dword 0
    push dword 0
    push dword 0
    push dword 0
.loop
    int 0x80
    inc ebx
    cmp ebx, 26
    jl .loop

    int 0xd

spin:
    jmp spin
