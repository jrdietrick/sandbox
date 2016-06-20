align 16, db 0

db 'userlib.asm', 0

align 16, db 0

global _exit, assert, check_sort, free, itoa, malloc, printf, puts, strcmp, strlen, strcpy

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

strcpy:
    push ebp
    mov ebp, esp
    push edi
    push esi

    mov edi, [ebp + 0x08]
    mov esi, [ebp + 0x0c]
.loop:
    cmp byte [esi], 0x00
    je .copy_null_terminator
    movsb
    jmp .loop
.copy_null_terminator:
    movsb

    pop esi
    pop edi
    leave
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
    push ebp
    mov ebp, esp

    ; Number of characters written (return value)
    push dword 0
    ; Newline and null terminator
    push dword 0x0000000a

    mov ecx, [ebp + 0x08]
    push dword 1 ; stdout
    push ecx
    call fputs
    add [ebp - 0x04], eax
    add esp, 4
    lea eax, [ebp - 0x08]
    push eax
    call fputs
    add [ebp - 0x04], eax
    add esp, 8

    add esp, 4
    pop eax

    leave
    ret

fputs:
    push ebp
    mov ebp, esp
    push ebx

    mov ecx, [ebp + 0x08]
    push ecx
    call strlen
    add esp, 4

    push eax

    mov edx, eax
    mov ebx, [ebp + 0x0c]
    mov eax, 4 ; write

    int 0x80

    pop eax

    pop ebx
    pop ebp
    ret

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
    push edx
    ; Keep going, unless both quotient AND carry
    ; are zero
    or edx, eax
    cmp edx, 0
    pop edx
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

printf:
    push ebp
    mov ebp, esp

    push esi
    push edi
    push ebx

    ; EBX = running index of variable arg number
    ; (0 is the first argument after the format
    ; string)
    xor ebx, ebx

    ; Set aside a buffer for itoa operations
    ; [ebp - 0x30]
    times 9 push dword 0x00000000

    ; Set aside a buffer for partial strings
    ; [ebp - 0x70]
    times 16 push dword 0x0000000

    ; Set aside a counter for characters written;
    ; this will be our return value
    push dword 0x00000000

    mov esi, [ebp + 0x08]
    lea edi, [ebp - 0x70]

.restart_loop:
    xor ecx, ecx
.loop:
    mov al, [esi]
    cmp al, 0x00
    je .flush_buffer
    cmp al, '%'
    je .maybe_format_specifier
.regular_character:
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    cmp ecx, 63
    je .flush_buffer
    jmp .loop

.maybe_format_specifier:
    ; See if it's '%%'
    inc esi
    mov al, [esi]
    cmp al, '%'
    je .regular_character
.is_format_specifier:
    ; First dump any buffer we have
    push eax
    mov byte [edi], 0x00
    lea edi, [ebp - 0x70]
    push dword 1
    push edi
    call fputs
    add esp, 8
    add [ebp - 0x74], eax
    pop eax

    ; Figure out which format specifier it is
    inc esi
    ; Check for %s
.check_format_string
    cmp al, 's'
    jne .check_format_integer
.format_string:
    ; It's %s, print a string
    mov eax, ebx
    inc ebx
    shl eax, 2
    lea eax, [eax + ebp + 0x0c]
    push dword 1
    push dword [eax]
    call fputs
    add esp, 8
    add [ebp - 0x74], eax
    jmp .restart_loop

    ; Check for %d
.check_format_integer:
    cmp al, 'd'
    jne assert_false
.format_integer:
    ; It's %d, print an integer

    ; Base 10
    push dword 10

    ; Buffer location
    lea eax, [ebp - 0x30]
    push eax

    ; Compute address of the argument
    mov eax, ebx
    inc ebx
    shl eax, 2
    lea eax, [eax + ebp + 0x0c]
    push dword [eax]

    call itoa
    add esp, 4
    mov dword [esp + 0x04], 1
    call fputs
    add esp, 8
    add [ebp - 0x74], eax
    jmp .restart_loop

.flush_buffer:
    ; Null terminate the partial string
    mov byte [edi], 0x00
    lea edi, [ebp - 0x70]
    push dword 1
    push edi
    call fputs
    add esp, 8
    add [ebp - 0x74], eax
    mov al, [esi]
    cmp al, 0x00
    je .done
    jmp .restart_loop

.done:
    ; Pop return value
    pop eax

    ; Kill the string and itoa buffers
    add esp, 0x24 + 0x40

    pop ebx
    pop edi
    pop esi

    leave
    ret

%include "allocator.asm"

memory_leak_detected: db 'MEMORY LEAK DETECTED', 0

align 16, db 0

_exit:
    call leak_check
    test eax, eax
    jz .no_leaks
    push memory_leak_detected
    call puts
    add esp, 4
.no_leaks:
    mov ebx, [esp + 0x04]
    mov eax, 1 ; exit
    int 0x80
