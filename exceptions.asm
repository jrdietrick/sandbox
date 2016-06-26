align 16, db 0

db 'exceptions.asm', 0

align 16, db 0

%define EXCEPTION_VECTOR_DOUBLE_FAULT 8
%define EXCEPTION_VECTOR_GENERAL_PROTECTION_FAULT 13
%define EXCEPTION_VECTOR_PAGE_FAULT 14

%macro generic_exception_handler 1
    push dword %1
    push dword exception_string_table + (%1 * 32)
    jmp exception_handler_common
%endmacro

exception_handler_0: generic_exception_handler 0
exception_handler_1: generic_exception_handler 1
exception_handler_2: generic_exception_handler 2
exception_handler_3: generic_exception_handler 3
exception_handler_4: generic_exception_handler 4
exception_handler_5: generic_exception_handler 5
exception_handler_6: generic_exception_handler 6
exception_handler_7: generic_exception_handler 7
exception_handler_8: generic_exception_handler 8
exception_handler_9: generic_exception_handler 9
exception_handler_10: generic_exception_handler 10
exception_handler_11: generic_exception_handler 11
exception_handler_12: generic_exception_handler 12
exception_handler_13: generic_exception_handler 13
exception_handler_14: generic_exception_handler 14
exception_handler_15: generic_exception_handler 15
exception_handler_16: generic_exception_handler 16
exception_handler_17: generic_exception_handler 17
exception_handler_18: generic_exception_handler 18
exception_handler_19: generic_exception_handler 19
exception_handler_20: generic_exception_handler 20
exception_handler_21: generic_exception_handler 21
exception_handler_22: generic_exception_handler 22
exception_handler_23: generic_exception_handler 23
exception_handler_24: generic_exception_handler 24
exception_handler_25: generic_exception_handler 25
exception_handler_26: generic_exception_handler 26
exception_handler_27: generic_exception_handler 27
exception_handler_28: generic_exception_handler 28
exception_handler_29: generic_exception_handler 29
exception_handler_30: generic_exception_handler 30
exception_handler_31: generic_exception_handler 31

exception_handler_common:
    pushad

    ; Push the faulting EIP
    mov edx, esp
    add edx, 0x28
    mov eax, [edx + 0x04]
    push eax

    ; Push the real ESP at the time of the fault
    push edx
    call get_real_esp
    add esp, 4
    push eax

    ; Get the exception code we pushed on to the
    ; stack right after we came in
    mov esi, [edx - 0x08]
    print_newline
    call println
    print_newline
    call exception_print_registers
    jmp exception_spin

exception_spin:
    cli
    hlt
    jmp exception_spin

get_real_esp:
    mov edx, [esp + 0x04]
    mov al, [edx + 0x08]
    and al, 0x03
    mov bx, cs
    and bx, 0x0003
    cmp al, bl
    je .no_privilege_level_change
    mov eax, [edx + 0x10]
    jmp .done
.no_privilege_level_change:
    mov eax, edx
    add eax, 0x10
.done:
    ret

exception_print_registers:
    ; We assume we're called right after a pushad,
    ; so all the registers are on the stack
    ; TODO: Is that safe? Is `pushad` hardware-
    ; independent?
    push ebp
    mov ebp, esp

    print_register eax, [ebp + 0x2c]
    print_space
    print_register ebx, [ebp + 0x20]
    print_space
    print_register ecx, [ebp + 0x28]
    print_space
    print_register edx, [ebp + 0x24]
    print_newline

    print_register esi, [ebp + 0x14]
    print_space
    print_register edi, [ebp + 0x10]
    print_space
    print_register ebp, [ebp + 0x18]
    print_space
    print_register esp, [ebp + 0x08]
    print_newline

    print_register eip, [ebp + 0x0c]
    print_newline

    pop ebp
    ret

align 32, db 0

exception_string_table:
    ; Each string must be 31 characters or less!
    ; (32 with the null terminator)
    ;  '-------------------------------', 0
    db 'DIVIDE ERROR (#DE)', 0
    align 32, db 0
    db 'DEBUG EXCEPTION (#DB)', 0
    align 32, db 0
    db 'NMI INTERRUPT', 0
    align 32, db 0
    db 'BREAKPOINT (#BP)', 0
    align 32, db 0
    db 'OVERFLOW (#OF)', 0
    align 32, db 0
    db 'BOUND RANGE EXCEEDED (#BR)', 0
    align 32, db 0
    db 'INVALID OPCODE (#UD)', 0
    align 32, db 0
    db 'DEVICE NOT AVAILABLE (#NM)', 0
    align 32, db 0
    db 'DOUBLE FAULT (#DF)', 0
    align 32, db 0
    db 'COPROCESSOR SEGMENT OVERRUN', 0
    align 32, db 0
    db 'INVALID TSS (#TS)', 0
    align 32, db 0
    db 'SEGMENT NOT PRESENT (#NP)', 0
    align 32, db 0
    db 'STACK-SEGMENT FAULT (#SS)', 0
    align 32, db 0
    db 'GENERAL PROTECTION FAULT (#GP)', 0
    align 32, db 0
    db 'PAGE FAULT (#PF)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#15)', 0
    align 32, db 0
    db 'X87 FPU ERROR (#MF)', 0
    align 32, db 0
    db 'ALIGNMENT CHECK (#AC)', 0
    align 32, db 0
    db 'MACHINE CHECK (#MC)', 0
    align 32, db 0
    db 'SIMD FP EXCEPTION (#XM)', 0
    align 32, db 0
    db 'VIRTUALIZATION EXCEPTION (#VE)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#21)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#22)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#23)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#24)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#25)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#26)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#27)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#28)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#29)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#30)', 0
    align 32, db 0
    db 'RESERVED EXCEPTION (#31)', 0

align 16, db 0

exception_jump_table:
    ; 0
    dd exception_handler_0
    dd exception_handler_1
    dd exception_handler_2
    dd exception_handler_3

    ; 4
    dd exception_handler_4
    dd exception_handler_5
    dd exception_handler_6
    dd exception_handler_7

    ; 8
    dd exception_handler_8
    dd exception_handler_9
    dd exception_handler_10
    dd exception_handler_11

    ; 12
    dd exception_handler_12
    dd exception_handler_13
    dd exception_handler_14
    dd exception_handler_15

    ; 16
    dd exception_handler_16
    dd exception_handler_17
    dd exception_handler_18
    dd exception_handler_19

    ; 20
    dd exception_handler_20
    dd exception_handler_21
    dd exception_handler_22
    dd exception_handler_23

    ; 24
    dd exception_handler_24
    dd exception_handler_25
    dd exception_handler_26
    dd exception_handler_27

    ; 28
    dd exception_handler_28
    dd exception_handler_29
    dd exception_handler_30
    dd exception_handler_31

    ; 32-47
    ; 8259 PIC
    ; IRQ 0
    dd 0
    dd keyboard_interrupt_handler
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
