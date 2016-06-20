use32

global _start

db 'USELESS PADDING TO TEST ENTRY POINTS NOT AT THE START OF THE BINARY', 0

align 16, db 0xff

_start:
    push dword string_to_print
    call puts
    add esp, 4

    push dword string_to_print
    call puts
    add esp, 4

    push dword 42
    call _exit

string_to_print: db 'this is a string from userspace!', 0

%include "userlib.asm"
