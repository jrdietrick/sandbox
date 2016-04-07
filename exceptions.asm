align 16, db 0

exception_handler:
    pushad
    mov esi, string_exception
    call print_string
    jmp exception_spin

exception_handler_8_double_fault:
    pushad
    mov esi, string_double_fault
    call print_string
    jmp exception_spin

exception_handler_13_general_protection_fault:
    pushad
    mov esi, string_general_protection_fault
    call print_string
    jmp exception_spin

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
    dd exception_handler
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
