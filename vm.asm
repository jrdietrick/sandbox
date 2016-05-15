align 16, db 0

db 'vm.asm', 0

align 16, db 0

%define PAGE_DIRECTORY_LOCATION 0x00001000
%define PAGE_DIRECTORY_LENGTH_DWORDS 1024
%define PTE_PRESENT FLAG(0)
%define PTE_RW FLAG(1)
%define PTE_USER_ACCESSIBLE FLAG(2)
%define PTE_4MB FLAG(7)

%define CR0_ENABLE_PAGING FLAG(31)
%define CR4_DEBUGGING_EXTENSIONS FLAG(3)
%define CR4_PAGE_SIZE_EXTENSION FLAG(4)
%define CR4_ENABLE_PAE FLAG(5)


basic_paging_setup:
    ; First zero out the page directory.
    ; TODO: is there a faster way to do
    ; this?
    push edi
    xor eax, eax
    mov ecx, PAGE_DIRECTORY_LENGTH_DWORDS
    mov edi, PAGE_DIRECTORY_LOCATION
    cld
    rep stosd

    ; Simple memory map for now:
    ; 0-4MB identity-paged for kernel
    ; 32-36MB identity-paged for usermode code
    ; 40-44MB identity-paged for usermode stack
    mov dword [PAGE_DIRECTORY_LOCATION + (4 * 0)], 0x00000000 | PTE_PRESENT | PTE_4MB
    mov dword [PAGE_DIRECTORY_LOCATION + (4 * 8)], 0x02000000 | PTE_PRESENT | PTE_USER_ACCESSIBLE | PTE_4MB
    mov dword [PAGE_DIRECTORY_LOCATION + (4 * 10)], 0x02800000 | PTE_PRESENT | PTE_RW | PTE_USER_ACCESSIBLE | PTE_4MB

    ; Turn paging on!
    mov eax, cr4
    and eax, DISABLE_FLAG(CR4_DEBUGGING_EXTENSIONS) & DISABLE_FLAG(CR4_ENABLE_PAE)
    or eax, CR4_PAGE_SIZE_EXTENSION
    mov cr4, eax

    mov eax, PAGE_DIRECTORY_LOCATION
    mov cr3, eax

    mov eax, cr0
    or eax, CR0_ENABLE_PAGING
    mov cr0, eax

    pop edi
    ret
