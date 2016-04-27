align 16, db 0

db 'syscalls.asm', 0

align 16, db 0

system_call_handler:
    mov ebp, esp
    push edx
    push ecx
    push ebx
    push eax

    mov esi, string_system_call
    call println

    mov eax, [ebp - 0x10] ; function code
    cmp eax, 4 ; write
    jne done
write:
    mov ebx, [ebp - 0x0c] ; file handle
    cmp ebx, 1 ; stdout
    jne done
write_stdout:
    nop

done:
    iret
