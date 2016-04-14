use32

global _start

start:
_start:
    mov dword [0x03000000], 4
    mov eax, 1
    int 128

spin:
    jmp spin
