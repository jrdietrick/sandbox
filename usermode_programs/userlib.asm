align 16, db 0

db 'userlib.asm', 0

align 16, db 0

global _exit, assert, check_sort, itoa, malloc, puts, strcmp, strlen

%define FLAG(x) (1 << x)
%define DISABLE_FLAG(x) (~x)

assert:
    mov eax, [esp + 0x04]
    cmp eax, 0
    je assert_false
    ret

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

strcmp:
    push ebp
    mov ebp, esp
    push ebx

    mov ecx, [ebp + 0x08]
    mov edx, [ebp + 0x0c]

.loop:
    mov al, [ecx]
    mov bl, [edx]
    cmp al, bl
    jg .greater
    jl .less
    cmp al, 0
    je .same
    inc ecx
    inc edx
    jmp .loop

.greater:
    mov eax, 1
    jmp .cleanup
.less:
    mov eax, -1
    jmp .cleanup
.same:
    mov eax, 0
.cleanup:
    pop ebx
    leave
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
    push ebx
    mov ebx, esp

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
    cmp esp, ebx
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

    pop ebx
    pop edi
    leave
    ret

%include "allocator.asm"