align 16, db 0

db 'userlib.asm', 0

align 16, db 0

global _exit
global check_sort
global itoa

assert_false:
    int 0x01

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

itoa:
    push ebp
    mov ebp, esp
    push edi

    ; Radix needs to be 10 (we don't support
    ; anything else at the moment)
    cmp dword [ebp + 0x10], 10
    je .base_10
    call assert_false
.base_10:
    mov edi, [ebp + 0x0c]
    mov eax, [ebp + 0x08]
.loop:
    xor edx, edx
    mov ecx, 10
    div ecx
    cmp edx, 0
    je .remainder_is_zero
    add edx, '0'
    push edx
    jmp .loop
.remainder_is_zero:
.loop2:
    cmp esp, ebp
    je .done2
    pop edx
    mov byte [edi], dl
    inc edi
    jmp .loop2
.done2:
    mov eax, [ebp + 0x0c]
    cmp edi, eax
    jne .wrote_something
    mov byte [edi], '0'
    inc edi
.wrote_something:
    mov byte [edi], 0x00

    pop edi
    leave
    ret