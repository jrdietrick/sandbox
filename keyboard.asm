align 16, db 0

db 'keyboard.asm', 0

align 16, db 0

%define KEYBOARD_STATUS_PORT 0x64
%define KEYBOARD_STATUS_HAS_KEY FLAG(0)

%define KEYBOARD_DATA_PORT 0x60

keyboard_interrupt_handler:
    pushad
    push dword 1
    call send_eoi
    add esp, 4
    popad
    iret
