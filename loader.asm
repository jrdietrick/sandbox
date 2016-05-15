align 16, db 0

db 'loader.asm', 0

align 16, db 0

%define USER_LOAD_LOCATION 0x02000000
%define USER_STACK_LOCATION 0x02400000

%define ELF_MAGIC 0x464c457f
%define ELF_32BIT 1
%define ELF_LITTLE_ENDIAN 1
%define ELF_VERSION 1
%define ELF_X86 0x03
%define ELF_SECTION_HEADER_ENTRY_SIZE 0x28
%define ELF_SECTION_HEADER_TYPE_STRTAB 0x00000003

text_section: db '.text', 0

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
    pop ebp
    ret

get_section_names_base:
    mov edx, [esp + 0x04]
    mov eax, [edx + 0x20]
    mov cx, [edx + 0x32] ; index of the section names section
    add edx, eax
.loop:
    cmp cx, 0
    je .done
    add edx, ELF_SECTION_HEADER_ENTRY_SIZE
    dec cx
    jmp .loop
.done:
    ; Double check this is the right section
    mov eax, [edx + 0x04]
    cmp eax, ELF_SECTION_HEADER_TYPE_STRTAB
    jne bad_elf_format
    mov eax, [edx + 0x10]
    ret

load_program:
    ; Calculate the starting address of
    ; the program we're loading on our
    ; "filesystem"
    mov ecx, [esp + 0x04]
    ; Programs are 4kB apart on disk
    shl ecx, 12
    lea esi, [ecx + 0xc000]

    ; Check the ELF header
    mov eax, [esi]
    cmp eax, ELF_MAGIC
    jne bad_elf_format
    mov al, [esi + 0x04]
    cmp al, ELF_32BIT
    jne bad_elf_format
    mov al, [esi + 0x05]
    cmp al, ELF_LITTLE_ENDIAN
    jne bad_elf_format
    mov al, [esi + 0x06]
    cmp al, ELF_VERSION
    jne bad_elf_format
    mov ax, [esi + 0x12]
    cmp ax, ELF_X86
    jne bad_elf_format
    ; Make sure section header entries are 40 bytes
    ; in size
    mov ax, [esi + 0x2e]
    cmp ax, ELF_SECTION_HEADER_ENTRY_SIZE
    jne bad_elf_format

    push esi
    call get_section_names_base
    add esp, 4

    ; push text_section
    ; push esi
    ; call find_section
    ; add esp, 8

    mov edi, USER_LOAD_LOCATION ; load program at 32MB
    mov ecx, 0x400 ; move 1024 dwords (4kB)
    rep movsd

    cli
    push dword USER_DATA_SEGMENT
    push dword USER_STACK_LOCATION
    pushfd
    or dword [esp], 0x200 ; re-enable interrupts when we reach usermode
    push dword USER_CODE_SEGMENT
    push dword USER_LOAD_LOCATION
    mov ax, USER_DATA_SEGMENT
    mov ds, ax
    iret

bad_elf_format:
    call assert_false
