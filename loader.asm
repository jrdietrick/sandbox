align 16, db 0

db 'loader.asm', 0

align 16, db 0

%define USER_CODE_PAGE_START 0x02000000
%define USER_CODE_PAGE_END 0x02400000
%define USER_DATA_PAGE_START 0x02800000
%define USER_DATA_PAGE_END 0x02c00000
%define USER_STACK_MAXIMUM_SIZE 0x00200000

; Offsets in the file header
%define ELF_HEADER_OFFSET_MAGIC 0x00
%define ELF_HEADER_OFFSET_BIT_SIZE 0x04
%define ELF_HEADER_OFFSET_ENDIANNESS 0x05
%define ELF_HEADER_OFFSET_VERSION 0x06
%define ELF_HEADER_OFFSET_ISA 0x12
%define ELF_HEADER_OFFSET_SECTION_HEADER_ENTRY_SIZE 0x2e
%define ELF_HEADER_OFFSET_SECTION_HEADER_OFFSET 0x20
%define ELF_HEADER_OFFSET_SECTION_ENTRIES_COUNT 0x30
%define ELF_HEADER_OFFSET_SECTION_NAMES_INDEX 0x32

; Offsets in the section header
%define ELF_SECTION_HEADER_OFFSET_NAME 0x00
%define ELF_SECTION_HEADER_OFFSET_TYPE 0x04
%define ELF_SECTION_HEADER_OFFSET_FLAGS 0x08
%define ELF_SECTION_HEADER_OFFSET_ADDRESS 0x0c
%define ELF_SECTION_HEADER_OFFSET_OFFSET 0x10
%define ELF_SECTION_HEADER_OFFSET_SIZE 0x14

; Offsets in relocation entries
%define ELF_RELOCATION_OFFSET_OFFSET 0x00
%define ELF_RELOCATION_OFFSET_TYPE 0x04

; Offsets in symbol table entries
%define ELF_SYMBOL_OFFSET_STRING_OFFSET 0x00
%define ELF_SYMBOL_OFFSET_OFFSET 0x04
%define ELF_SYMBOL_OFFSET_TYPE 0x0c
%define ELF_SYMBOL_OFFSET_INDEX 0x0e

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
%define ELF_SYMBOL_TYPE_SECTION 0x03
%define ELF_RELOCATION_TYPE_R_386_32 0x01
%define ELF_RELOCATION_TYPE_R_386_PC32 0x02

text_section: db '.text', 0
text_relocation_section: db '.rel.text', 0
symbol_table_section: db '.symtab', 0
string_table_section: db '.strtab', 0
read_only_data_section: db '.rodata', 0
data_section: db '.data', 0

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
    mov eax, [edx + ELF_HEADER_OFFSET_SECTION_HEADER_OFFSET]
    mov cx, [edx + ELF_HEADER_OFFSET_SECTION_NAMES_INDEX] ; index of the section names section
    add edx, eax
.loop:
    cmp cx, 0
    je .done
    add edx, ELF_SECTION_HEADER_ENTRY_SIZE
    dec cx
    jmp .loop
.done:
    ; Double check this is the right section
    mov eax, [edx + ELF_SECTION_HEADER_OFFSET_TYPE]
    cmp eax, ELF_SECTION_HEADER_TYPE_STRTAB
    jne bad_elf_format
    mov eax, [edx + ELF_SECTION_HEADER_OFFSET_OFFSET]
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

    mov eax, [esi + ELF_HEADER_OFFSET_SECTION_HEADER_OFFSET]
    add eax, esi
    mov cx, [esi + ELF_HEADER_OFFSET_SECTION_ENTRIES_COUNT]
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

get_section_index_by_header_entry_base:
    ; ESI must be the base of the full ELF
    push ebp
    mov ebp, esp

    mov eax, [ebp + 0x08]
    mov edx, [esi + ELF_HEADER_OFFSET_SECTION_HEADER_OFFSET]
    add edx, esi
    sub eax, edx
    xor edx, edx
    mov ecx, ELF_SECTION_HEADER_ENTRY_SIZE
    ; divide EDX:EAX / ECX
    div ecx

    leave
    ret

get_symbol_table_entry_by_index:
    ; ESI must be the base of the full ELF
    push symbol_table_section
    call find_section_header_entry
    add esp, 4

    ; EAX = base of the symbol table
    mov eax, [eax + ELF_SECTION_HEADER_OFFSET_OFFSET]
    add eax, esi

    ; ECX = symbol index
    mov ecx, [esp + 0x04]
    shl ecx, ELF_SYMBOL_TABLE_ENTRY_SIZE_LOG
    add eax, ecx
    ret

get_symbol_table_entry_by_section_index:
    push ebp
    mov ebp, esp

    ; ESI must be the base of the full ELF
    push symbol_table_section
    call find_section_header_entry
    add esp, 4

    ; ECX = number of entries in symbol table
    mov ecx, [eax + ELF_SECTION_HEADER_OFFSET_SIZE]
    shr ecx, ELF_SYMBOL_TABLE_ENTRY_SIZE_LOG

    ; EDX = base of the symbol table
    mov edx, [eax + ELF_SECTION_HEADER_OFFSET_OFFSET]
    add edx, esi

    ; EAX = index we're looking for
    mov eax, [ebp + 0x08]
    ; EAX = type and index we're looking for; type
    ; is in the low 16 bits, index in the top 16
    shl eax, 16
    add eax, ELF_SYMBOL_TYPE_SECTION

.loop:
    cmp ecx, 0
    je bad_elf_format ; if we hit zero, not found!
    push ecx

    mov ecx, [edx + ELF_SYMBOL_OFFSET_TYPE]
    cmp ecx, eax
    pop ecx
    je .found

    add edx, ELF_SYMBOL_TABLE_ENTRY_SIZE
    dec ecx
    jmp .loop
.found:
    mov eax, edx
    leave
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
    mov ebx, [eax + ELF_SECTION_HEADER_OFFSET_OFFSET]
    add ebx, esi

    push symbol_table_section
    call find_section_header_entry
    add esp, 4

    ; ECX = number of entries in symbol table
    mov ecx, [eax + ELF_SECTION_HEADER_OFFSET_SIZE]
    shr ecx, ELF_SYMBOL_TABLE_ENTRY_SIZE_LOG

    ; EDX = base of the symbol table
    mov edx, [eax + ELF_SECTION_HEADER_OFFSET_OFFSET]
    add edx, esi

.loop:
    cmp ecx, 0
    je bad_elf_format ; if we hit zero, not found!

    ; strcmp will clobber ECX and EDX
    push ecx
    push edx

    ; Calculate the address of the string in
    ; the string table
    mov eax, [edx + ELF_SYMBOL_OFFSET_STRING_OFFSET]
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
    mov ecx, [eax + ELF_SECTION_HEADER_OFFSET_SIZE]
    shr ecx, ELF_RELOCATION_ENTRY_SIZE_LOG

    mov edx, [eax + ELF_SECTION_HEADER_OFFSET_OFFSET]
    add edx, esi

.loop:
    cmp ecx, 0
    je .done
    ; We'll actually check the relocation type
    ; a little further down...
    mov eax, [edx + ELF_RELOCATION_OFFSET_TYPE]
    shr eax, 8

    push edx
    push ecx

    ; Get the symbol table entry by index
    push eax
    call get_symbol_table_entry_by_index
    add esp, 4
    ; EAX = offset to the symbol table entry

    ; The offset in the symbol table is relative to
    ; the beginning of a given section. So perform a
    ; second lookup to get the load location of that
    ; section.
    push eax
    xor ebx, ebx
    mov bx, [eax + ELF_SYMBOL_OFFSET_INDEX]
    push ebx
    call get_symbol_table_entry_by_section_index
    add esp, 4
    mov ebx, eax
    pop eax

    pop ecx
    pop edx

    ; EBX = symbol offset (relocation target)
    mov ebx, [ebx + ELF_SYMBOL_OFFSET_OFFSET]
    add ebx, [eax + ELF_SYMBOL_OFFSET_OFFSET]
    add ebx, USER_CODE_PAGE_START

    ; EDI = location of the relocation
    ; (the memory to be modified)
    mov edi, [edx + ELF_RELOCATION_OFFSET_OFFSET]
    add edi, USER_CODE_PAGE_START

    ; Perform the actual relocation now.
    ; Check the type:
    mov eax, [edx + ELF_RELOCATION_OFFSET_TYPE]
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

load_section:
    push ebp
    mov ebp, esp
    push edi
    push ebx

    mov esi, [ebp + 0x08]

    ; Find the section header entry
    push dword [ebp + 0x0c]
    call find_section_header_entry
    add esp, 4

    cmp eax, NULL
    je .section_not_exist

    push eax
    call get_section_index_by_header_entry_base
    mov ebx, eax
    pop eax

    ; ESI = source location
    mov ecx, [eax + ELF_SECTION_HEADER_OFFSET_OFFSET]
    add esi, ecx

    ; ECX = number of bytes
    mov ecx, [eax + ELF_SECTION_HEADER_OFFSET_SIZE]
    cmp ecx, 0
    je .section_not_exist
    ; Check against the limit passed on the stack
    mov edx, [ebp + 0x10]
    add edx, ecx
    mov edi, [ebp + 0x14]
    cmp edx, edi
    jg bad_elf_format

    ; ECX = number of dwords
    add ecx, 3
    shr ecx, 2

    ; Where to load is passed on the stack; stash it
    ; in EDX so we can use it later
    mov edi, [ebp + 0x10]
    mov edx, edi
    sub edx, USER_CODE_PAGE_START

    ; Copy it in!
    rep movsd

    ; Reset ESI
    mov esi, [ebp + 0x08]

    ; Now update the symbol table so that relocation
    ; will link things up as expected!
    push edx
    push ebx
    call get_symbol_table_entry_by_section_index
    add esp, 4
    pop edx

    mov [eax + ELF_SYMBOL_OFFSET_OFFSET], edx

.section_not_exist:
    pop ebx
    pop edi
    leave
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
    mov eax, [esi + ELF_HEADER_OFFSET_MAGIC]
    cmp eax, ELF_MAGIC
    jne bad_elf_format
    mov al, [esi + ELF_HEADER_OFFSET_BIT_SIZE]
    cmp al, ELF_32BIT
    jne bad_elf_format
    mov al, [esi + ELF_HEADER_OFFSET_ENDIANNESS]
    cmp al, ELF_LITTLE_ENDIAN
    jne bad_elf_format
    mov al, [esi + ELF_HEADER_OFFSET_VERSION]
    cmp al, ELF_VERSION
    jne bad_elf_format
    mov ax, [esi + ELF_HEADER_OFFSET_ISA]
    cmp ax, ELF_X86
    jne bad_elf_format
    ; Make sure section header entries are 40 bytes
    ; in size
    mov ax, [esi + ELF_HEADER_OFFSET_SECTION_HEADER_ENTRY_SIZE]
    cmp ax, ELF_SECTION_HEADER_ENTRY_SIZE
    jne bad_elf_format

.load_text: ; Load .text
    push USER_DATA_PAGE_END
    push USER_CODE_PAGE_START
    push text_section
    push esi
    call load_section
    pop esi
    add esp, 12

.load_rodata: ; Load the .rodata section
    ; EDI is sitting where we left it after copying
    ; .text. Align to 16 bytes, and this is where we
    ; will start copying the next section.
    add edi, 15
    and edi, 0xfffffff0

    push USER_CODE_PAGE_END ; far bound on the page
    push edi
    push read_only_data_section
    push esi
    call load_section
    pop esi
    add esp, 12

.load_data: ; Load the .data section
    ; Technically .data could use up to 4MB, because
    ; that's the size of our data page, but we are
    ; sharing that space with the stack, so we don't
    ; want to cramp things too much. Allow the stack
    ; to have 2MB, and the rest can be used for data
    push USER_DATA_PAGE_END - USER_STACK_MAXIMUM_SIZE
    push USER_DATA_PAGE_START
    push data_section
    push esi
    call load_section
    pop esi
    add esp, 12

    call perform_relocations

    ; Calculate the entry point
    push entry_point_symbol
    call get_symbol_table_entry_by_string
    add esp, 4
    mov eax, [eax + ELF_SYMBOL_OFFSET_OFFSET]
    add eax, USER_CODE_PAGE_START

    cli
    push dword USER_DATA_SEGMENT
    push dword USER_DATA_PAGE_END
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
