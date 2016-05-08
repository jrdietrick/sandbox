align 16, db 0

db 'exceptions.asm', 0

align 16, db 0

exception_handler:
    pushad
    print_newline
    mov esi, string_exception
    call println
    print_newline
    call print_registers
    jmp exception_spin

exception_handler_8_double_fault:
    pushad
    mov esi, string_double_fault
    call println
    jmp exception_spin

exception_handler_13_general_protection_fault:
    pushad
    print_newline
    mov esi, string_general_protection_fault
    call println
    print_newline
    call print_registers
    mov eax, [esp + 0x0c] ; saved ESP
    push eax
    call print_exception_stack
    add esp, 4
    jmp exception_spin

exception_handler_14_page_fault:
    mov esi, string_page_fault
    call println
    jmp exception_spin

rtc_tick:
    pushad
    ; Print a nice string
    mov esi, string_pic_interrupt
    call println
    ; Acknowledge the RTC tick
    call rtc_clear
    ; Send the EOI to the PIC
    push dword 8
    call send_eoi
    add esp, 4
    popad
    iret

exception_spin:
    cli
    hlt
    jmp exception_spin

align 16, db 0

exception_jump_table:
    ; 0
    dd exception_handler
    dd exception_handler
    dd exception_handler
    dd exception_handler

    ; 4
    dd exception_handler
    dd exception_handler
    dd exception_handler
    dd exception_handler

    ; 8
    dd exception_handler_8_double_fault
    dd exception_handler
    dd exception_handler
    dd exception_handler

    ; 12
    dd exception_handler
    dd exception_handler_13_general_protection_fault
    dd exception_handler_14_page_fault
    dd exception_handler

    ; 16
    dd exception_handler
    dd exception_handler
    dd exception_handler
    dd exception_handler

    ; 20
    dd exception_handler
    dd exception_handler
    dd exception_handler
    dd exception_handler

    ; 24
    dd exception_handler
    dd exception_handler
    dd exception_handler
    dd exception_handler

    ; 28
    dd exception_handler
    dd exception_handler
    dd exception_handler
    dd exception_handler

    ; 32-47
    ; 8259 PIC
    ; IRQ 0
    dd 0
    dd 0
    dd 0
    dd 0
    dd 0
    dd 0
    dd 0
    dd 0

    ; IRQ 8
    dd rtc_tick
    dd 0
    dd 0
    dd 0
    dd 0
    dd 0
    dd 0
    dd 0

    ; 48-127
    times 80 dd 0

    ; 128
    dd system_call_handler
