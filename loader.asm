align 16, db 0

db 'loader.asm', 0

align 16, db 0

%define USER_LOAD_LOCATION 0x02000000
%define USER_STACK_LOCATION 0x02c00000

%define ELF_MAGIC 0x464c457f
%define ELF_32BIT 1
%define ELF_LITTLE_ENDIAN 1
%define ELF_VERSION 1
%define ELF_X86 0x03
%define ELF_SECTION_HEADER_ENTRY_SIZE 0x28
%define ELF_SECTION_HEADER_TYPE_PROGBITS 0x00000001
%define ELF_SECTION_HEADER_TYPE_STRTAB 0x00000003
%define ELF_RELOCATION_ENTRY_SIZE 8
%define ELF_RELOCATION_ENTRY_SIZE_LOG 3 ; relocation entries are 8 bytes each
%define ELF_SYMBOL_TABLE_ENTRY_SIZE 16
%define ELF_SYMBOL_TABLE_ENTRY_SIZE_LOG 4 ; symbol table entries are 16 bytes each
%define ELF_RELOCATION_TYPE_R_386_32 0x01
%define ELF_RELOCATION_TYPE_R_386_PC32 0x02

text_section: db '.text', 0
text_relocation_section: db '.rel.text', 0
symbol_table_section: db '.symtab', 0
string_table_section: db '.strtab', 0
read_only_data_section: db '.rodata', 0

entry_point_symbol: db '_start', 0

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
    add eax, [esp + 0x04]
    ret

find_section_header_entry:
    ; ESI must be the base of the full ELF
    push ebp
    mov ebp, esp
    push ebx

    push esi
    call get_section_names_base
    add esp, 4
    mov ebx, eax
    ; EBX = base of the section names string table

    mov eax, [esi + 0x20]
    add eax, esi
    mov cx, [esi + 0x30]
.loop:
    cmp cx, 0
    je .not_found ; if we hit zero, not found!
    mov edx, [eax]
    add edx, ebx

    push eax
    push ecx
    push edx
    mov edx, [ebp + 0x08]
    push edx
    call strcmp
    mov edx, eax
    add esp, 8
    pop ecx
    pop eax

    cmp edx, 0
    je .found
    dec ecx
    add eax, ELF_SECTION_HEADER_ENTRY_SIZE
    jmp .loop
.not_found:
    mov eax, NULL
.found:
    pop ebx
    pop ebp
    ret

get_symbol_table_entry_by_index:
    ; ESI must be the base of the full ELF
    push symbol_table_section
    call find_section_header_entry
    add esp, 4

    ; EAX = base of the symbol table
    mov eax, [eax + 0x10]
    add eax, esi

    ; ECX = symbol index
    mov ecx, [esp + 0x04]
    shl ecx, ELF_SYMBOL_TABLE_ENTRY_SIZE_LOG
    add eax, ecx
    ret

get_symbol_table_entry_by_string:
    ; ESI must be the base of the full ELF
    push ebp
    mov ebp, esp
    push ebx

    ; EBX = location of the string table
    push string_table_section
    call find_section_header_entry
    add esp, 4
    mov ebx, [eax + 0x10]
    add ebx, esi

    push symbol_table_section
    call find_section_header_entry
    add esp, 4

    ; ECX = number of entries in symbol table
    mov ecx, [eax + 0x14]
    shr ecx, ELF_SYMBOL_TABLE_ENTRY_SIZE_LOG

    ; EDX = base of the symbol table
    mov edx, [eax + 0x10]
    add edx, esi

.loop:
    cmp ecx, 0
    je bad_elf_format ; if we hit zero, not found!

    ; strcmp will clobber ECX and EDX
    push ecx
    push edx

    ; Calculate the address of the string in
    ; the string table
    mov eax, [edx + 0x00] ; offset
    add eax, ebx
    push eax
    ; Compare with the string passed to this
    ; function as a parameter
    mov eax, [ebp + 0x08]
    push eax
    call strcmp
    add esp, 8
    pop edx
    pop ecx

    cmp eax, 0
    je .found

    add edx, ELF_SYMBOL_TABLE_ENTRY_SIZE
    dec ecx
    jmp .loop
.found:
    mov eax, edx
    pop ebx
    pop ebp
    ret

perform_relocations:
    ; ESI must be the base of the full ELF
    push ebp
    mov ebp, esp
    push ebx
    push edi

    push text_relocation_section
    call find_section_header_entry
    add esp, 4

    ; From the size of the relocation section, find
    ; out how many relocation entries there are
    mov ecx, [eax + 0x14]
    shr ecx, ELF_RELOCATION_ENTRY_SIZE_LOG

    mov edx, [eax + 0x10]
    add edx, esi

.loop:
    cmp ecx, 0
    je .done
    ; We'll actually check the relocation type
    ; a little further down...
    mov eax, [edx + 0x04]
    shr eax, 8

    ; Get the symbol table entry by index
    push edx
    push ecx
    push eax
    call get_symbol_table_entry_by_index
    add esp, 4
    pop ecx
    pop edx
    ; EAX = offset to the symbol table entry

    ; EBX = symbol offset (relocation target)
    mov ebx, USER_LOAD_LOCATION
    add ebx, [eax + 0x04]

    ; EDI = location of the relocation
    ; (the memory to be modified)
    mov edi, [edx + 0x00]
    add edi, USER_LOAD_LOCATION

    ; Perform the actual relocation now.
    ; Check the type:
    mov eax, [edx + 0x04]
    cmp al, ELF_RELOCATION_TYPE_R_386_PC32
    je .r_386_pc32
    cmp al, ELF_RELOCATION_TYPE_R_386_32
    jne bad_elf_format

.r_386_32:
    ; For R_386_32, we just take the final target
    ; and add it to whatever is already occupying
    ; that memory address
    mov eax, [edi]
    add eax, ebx
    mov [edi], eax
    jmp .relocation_done
.r_386_pc32:
    ; For R_386_32, we take the final target MINUS
    ; the location in memory we're adjusting (to
    ; construct an EIP-relative call) and then
    ; adjust it by whatever is already occupying
    ; that memory address
    mov eax, ebx
    sub eax, edi
    add eax, [edi]
    mov [edi], eax

.relocation_done:
    dec ecx
    add edx, ELF_RELOCATION_ENTRY_SIZE
    jmp .loop
.done:
    pop edi
    pop ebx
    pop ebp
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

    ; Find the .text section entry
    push text_section
    call find_section_header_entry
    add esp, 4

    ; Make sure it's a progbits section
    mov ecx, [eax + 0x04]
    cmp ecx, ELF_SECTION_HEADER_TYPE_PROGBITS
    jne bad_elf_format

    push esi

    ; Get the source location using the offset
    mov ecx, [eax + 0x10]
    add esi, ecx

    ; Get the number of bytes
    mov ecx, [eax + 0x14]
    add ecx, 3
    shr ecx, 2 ; convert to dwords

    ; Load .data at 32MB (0x2000000)
    mov edi, USER_LOAD_LOCATION
    rep movsd

    ; Reset ESI, but leave on the stack
    mov esi, [esp + 0x00]

    ; Find the .rodata section entry
    push read_only_data_section
    call find_section_header_entry
    add esp, 4

    cmp eax, NULL
    je .no_rodata

    ; ESI = source location
    mov ecx, [eax + 0x10]
    add esi, ecx

    ; ECX = number of bytes
    mov ecx, [eax + 0x14]
    cmp ecx, 0
    je .no_rodata
    ; ECX = number of dwords
    add ecx, 3
    shr ecx, 2

    ; EDI is sitting at where we left it after
    ; copying .text. Align to 16 bytes and copy it
    ; to EDX for later use, too.
    add edi, 15
    and edi, 0xfffffff0
    mov edx, edi

    ; Copy it in!
    rep movsd

.no_rodata:
    pop esi
    call perform_relocations

    ; Calculate the entry point
    push entry_point_symbol
    call get_symbol_table_entry_by_string
    add esp, 4
    mov eax, [eax + 0x04]
    add eax, USER_LOAD_LOCATION

    cli
    push dword USER_DATA_SEGMENT
    push dword USER_STACK_LOCATION
    pushfd
    or dword [esp], 0x200 ; re-enable interrupts when we reach usermode
    push dword USER_CODE_SEGMENT
    push dword eax
    mov ax, USER_DATA_SEGMENT
    mov ds, ax

    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi
    xor ebp, ebp
    iret

bad_elf_format:
    call assert_false
