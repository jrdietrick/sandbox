align 16, db 0

db 'userlib.asm', 0

align 16, db 0

global _exit
global check_sort

strlen:
    xor eax, eax
    mov edx, [esp + 0x04] ; pointer to buffer
.loop:
    cmp byte [edx], 0x00
    je .done
    inc eax
    inc edx
    jmp .loop
.done:
    ret

puts:
    mov ecx, [esp + 0x04]
    push dword 1 ; stdout
    push ecx
    call fputs
    add esp, 8
    ret

fputs:
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 0x08]
    push ecx
    call strlen
    add esp, 4

    mov edx, eax
    mov ebx, [ebp + 0x0c]
    mov eax, 4 ; write

    int 0x80

    pop ebp
    ret

_exit:
    mov ebx, [esp + 0x04]
    mov eax, 1 ; exit
    int 0x80

check_sort:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    ; EAX = result
    ; 0 = not sorted (or not an array)
    ; 1 = sorted
    xor eax, eax
    ; EDX = cursor (int*)
    mov edx, [ebp + 0x08]
    ; ECX = counter
    mov ecx, [ebp + 0x0c]
    cmp ecx, 0
    jle .invalid
    ; We'll start our loop from index 1
    ; ESI = previous value
    mov esi, [edx]
    add edx, 4
    dec ecx
.loop:
    cmp ecx, 0
    je .sorted
    mov ebx, [edx]
    cmp esi, ebx
    jg .not_sorted
    mov esi, ebx
    add edx, 4
    dec ecx
    jmp .loop
.sorted:
    inc eax
.not_sorted:
.invalid:
    pop esi
    pop ebx
    leave
    ret
