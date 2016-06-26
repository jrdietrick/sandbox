align 16, db 0

db 'syscalls.asm', 0

align 16, db 0

system_call_handler:
    pushad
    mov ebp, esp
    push edx
    push ecx
    push ebx
    push eax

    cmp eax, 0x01 ; exit
    je system_call_exit

    cmp eax, 0x04 ; write
    je system_call_write

    cmp eax, 0xa2 ; sleep
    je system_call_sleep

    call assert_false

system_call_exit:
    ; Just halt the processor, printing the status
    ; code sent in EBX (the return code)
    mov esi, string_system_call_halt
    call println
    print_register ebx, ebx
    cli
.spin:
    hlt
    jmp .spin

system_call_write:
    mov ebx, [ebp - 0x0c] ; file handle
    cmp ebx, 1 ; stdout
    jne .done
.allocate_kernel_buffer:
    ; Figure out the buffer length and
    ; allocate space (on the stack for now
    ; because we're poor)
    mov ecx, [ebp - 0x04]
    mov eax, ecx
    add eax, 1 ; for null terminator, so we can use puts
    ; Ceiling to 4 and then divide by 4, to
    ; get the number of dwords we need to
    ; allocate
    add eax, 3
    shr eax, 2
.allocate_loop:
    cmp eax, 0
    je .allocate_done
    push dword 0x00000000
    dec eax
    jmp .allocate_loop
.allocate_done:
    mov edi, esp
.copy_kernel_buffer:
    ; Copy the usermode buffer into the kernel
    ; space we just allocated
    mov esi, [ebp - 0x08]
    rep movsb
.do_the_puts:
    ; Put those characters onto the screen!
    mov esi, esp
    call puts
.done:
    mov esp, ebp
    popad
    iret

system_call_sleep:
    iret
