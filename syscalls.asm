align 16, db 0

db 'syscalls.asm', 0

align 16, db 0

system_call_handler:
    mov esi, string_system_call
    call println
    iret
