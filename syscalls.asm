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

    cmp eax, 0x03 ; read
    je system_call_read

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

system_call_read:
    mov ebx, [ebp - 0x0c] ; file handle
    cmp ebx, 0 ; stdin
    je .stdin
    call assert_false
.stdin:
.outer_loop:
    cmp dword [ebp - 0x04], 0 ; compare against remaining bytes count
    je .done
.wait_on_stdin:
    call keyboard_bytes_ready
    cmp eax, 0
    jne .stdin_ready
    hlt
    jmp .wait_on_stdin
.stdin_ready:
    cmp [ebp - 0x04], eax
    ; If the number of bytes left to read is less
    ; than the number available, only read the
    ; remaining count
    jge .read_from_keyboard_buffer
    mov eax, [ebp - 0x04]
.read_from_keyboard_buffer:
    push eax
    mov ecx, eax
    mov edx, [ebp - 0x08]
.read_from_keyboard_buffer_loop:
    cmp ecx, 0
    je .read_from_keyboard_buffer_done

    push ecx
    push edx
    call keyboard_buffer_extract
    pop edx
    pop ecx

    mov [edx], al
    inc edx
    dec ecx
    jmp .read_from_keyboard_buffer_loop
.read_from_keyboard_buffer_done:
    pop eax
    sub [ebp - 0x04], eax
    mov [ebp - 0x08], edx
    jmp .outer_loop
.done:
    mov esp, ebp
    popad
    iret

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
    push ebx
    call rtc_sleep
    add esp, 4

    mov esp, ebp
    popad
    iret
