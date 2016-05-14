align 16, db 0

db 'keyboard.asm', 0

align 16, db 0

%define KEYBOARD_STATUS_PORT 0x64
%define KEYBOARD_STATUS_HAS_KEY FLAG(0)

%define KEYBOARD_DATA_PORT 0x60

%define NON_PRINTABLE_CHARACTER 0xff
%define NPC NON_PRINTABLE_CHARACTER

keyboard_interrupt_handler:
    pushad

.read:
    in al, KEYBOARD_STATUS_PORT
    and al, KEYBOARD_STATUS_HAS_KEY
    jz .done
    in al, KEYBOARD_DATA_PORT
    jmp .read
.done:
    push dword 1
    call send_eoi
    add esp, 4
    popad
    iret

align 16, db 0

scancode_table:
    db NPC, NPC, '1', '2', '3', '4', '5', '6'
    db '7', '8', '9', '0', '-', '=', NPC, NPC
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'
    db 'o', 'p', '[', ']', 0xa, NPC, 'a', 's'
    db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'
    db 0x27, '`', NPC, '\', 'z', 'x', 'c', 'v'
    db 'b', 'n', 'm', ',', '.', '/', NPC, NPC
    db NPC, ' ', NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, '!', '@', '#', '$', '%', '^'
    db '&', '*', '(', ')', '_', '+', NPC, NPC
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I'
    db 'O', 'P', '[', ']', 0xa, NPC, 'A', 'S'
    db 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':'
    db '"', '~', NPC, '|', 'Z', 'X', 'C', 'V'
    db 'B', 'N', 'M', '<', '>', '?', NPC, NPC
    db NPC, ' ', NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC
    db NPC, NPC, NPC, NPC, NPC, NPC, NPC, NPC