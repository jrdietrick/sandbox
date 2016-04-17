align 16, db 0

db 'vm.asm', 0

align 16, db 0


%define PAGE_DIRECTORY_LOCATION 0x00001000
%define PAGE_DIRECTORY_LENGTH_DWORDS 1024


basic_paging_setup:
    ; First zero out the page directory.
    ; TODO: is there a faster way to do
    ; this?
    mov dword [PAGE_DIRECTORY_LOCATION + 0x100], 0x88888888
    push edi
    xor eax, eax
    mov ecx, PAGE_DIRECTORY_LENGTH_DWORDS
    mov edi, PAGE_DIRECTORY_LOCATION
    cld
    rep stosd
    pop edi
    ret
