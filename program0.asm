use32

global _start

start:
_start:
    mov dword [0x03000000], 4
    mov dword [0x8000], 0x0

spin:
    jmp spin
