align 16, db 0

db 'loader.asm', 0

align 16, db 0

%define USER_LOAD_LOCATION 0x02000000
%define USER_STACK_LOCATION 0x02400000

load_program:
    ; Calculate the starting address of
    ; the program we're loading on our
    ; "filesystem"
    mov esi, 0xc000
    mov ecx, [esp + 0x04]
    shl ecx, 9
    add esi, ecx
    mov edi, USER_LOAD_LOCATION ; load program at 32MB
    mov ecx, 0x80 ; move 128 dwords (one sector)
    rep movsd

    cli
    push dword USER_DATA_SEGMENT
    push dword USER_STACK_LOCATION
    pushfd
    or dword [esp], 0x200 ; re-enable interrupts when we reach usermode
    push dword USER_CODE_SEGMENT
    push dword USER_LOAD_LOCATION
    mov ax, USER_DATA_SEGMENT
    mov ds, ax
    iret
