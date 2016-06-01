align 16, db 0

db 'allocator.asm', 0

align 16, db 0

; Map of "the slab" -- the kernel's virtual memory manager gives
; us one 4MB slab of memory, which for now happens to be at 48MB
; in the virtual address space (0x03000000). Here's how we've
; decided to slice it up, using 93.75% of it for program-ready
; memory, and the rest for overhead.
;
; Notice tier 7 is a little smaller than the rest to allow us
; that 256kB we'll use for tracking what has been doled out.
;
; Slab base:
;  0x03000000
; +0x       0  +------------------------------------------------+
;              | Tier 0                                         |
;              | 32,768 x 16-byte blocks                        |
;              | (512kB, requires 4kB of bitmask)               |
; +0x   80000  +------------------------------------------------+
;              | Tier 1                                         |
;              | 16,384 x 32-byte blocks                        |
;              | (512kB, requires 2kB of bitmask)               |
; +0x  100000  +------------------------------------------------+
;              | Tier 2                                         |
;              | 8,192 x 64-byte blocks                         |
;              | (512kB, requires 1kB of bitmask)               |
; +0x  180000  +------------------------------------------------+
;              | Tier 3                                         |
;              | 4,096 x 128-byte blocks                        |
;              | (512kB, requires 512 bytes of bitmask)         |
; +0x  200000  +------------------------------------------------+
;              | Tier 4                                         |
;              | 2,048 x 256-byte blocks                        |
;              | (512kB, requires 256 bytes of bitmask)         |
; +0x  280000  +------------------------------------------------+
;              | Tier 5                                         |
;              | 1,024 x 512-byte blocks                        |
;              | (512kB, requires 128 bytes of bitmask)         |
; +0x  300000  +------------------------------------------------+
;              | Tier 6                                         |
;              | 512 x 1kB blocks                               |
;              | (512kB, requires 64 bytes of bitmask)          |
; +0x  380000  +------------------------------------------------+
;              | Tier 7                                         |
;              | 64 x 4kB blocks                                |
;              | (256kB, requires 8 bytes of bitmask)           |
; +0x  3c0000  +------------------------------------------------+
;              | Bitmask for tier 0                             |
;              | 4kB allocated, all used by bitmask             |
; +0x  3c1000  +------------------------------------------------+
;              | Bitmask for tier 1                             |
;              | 4kB allocated, but only 2kB used               |
; +0x  3c2000  +------------------------------------------------+
;              | Bitmask for tier 2                             |
; +0x  3c3000  +------------------------------------------------+
;              | Bitmask for tier 3                             |
; +0x  3c4000  +------------------------------------------------+
;              | Bitmask for tier 4                             |
; +0x  3c5000  +------------------------------------------------+
;              | Bitmask for tier 5                             |
; +0x  3c6000  +------------------------------------------------+
;              | Bitmask for tier 6                             |
; +0x  3c7000  +------------------------------------------------+
;              | Bitmask for tier 7                             |
; +0x  3c8000  +------------------------------------------------+
;              | General control bits                           |
; +0x  3c8010  +------------------------------------------------+
;              | (unused, ~224kB)                               |
; +0x  400000  +------------------------------------------------+

%define TIER_COUNT 8
%define SLAB_BASE 0x03000000

%define TIER_0_ALLOCATION_POWER 4
%define TIER_1_ALLOCATION_POWER 5
%define TIER_2_ALLOCATION_POWER 6
%define TIER_3_ALLOCATION_POWER 7
%define TIER_4_ALLOCATION_POWER 8
%define TIER_5_ALLOCATION_POWER 9
%define TIER_6_ALLOCATION_POWER 10
%define TIER_7_ALLOCATION_POWER 12

%define TIER_0_ALLOCATION_COUNT (1 << 15)
%define TIER_1_ALLOCATION_COUNT (1 << 14)
%define TIER_2_ALLOCATION_COUNT (1 << 13)
%define TIER_3_ALLOCATION_COUNT (1 << 12)
%define TIER_4_ALLOCATION_COUNT (1 << 11)
%define TIER_5_ALLOCATION_COUNT (1 << 10)
%define TIER_6_ALLOCATION_COUNT (1 << 9)
%define TIER_7_ALLOCATION_COUNT (1 << 6)

%define TIER_ALLOCATION_START_OFFSET_POWER_2 19 ; tiers are 512kB apart

%define CONTROL_REGION_START 0x003c0000
%define CONTROL_REGION_BYTES_PER_TIER 4096

%define ALLOCATOR_FLAGS_LOCATION 0x003c8000
%define ALLOCATOR_INITIALIZED FLAG(0)

%macro check_size_against_tier 1
    mov dword [esp + 0x08], TIER_%1_ALLOCATION_COUNT
    mov dword [esp + 0x04], TIER_%1_ALLOCATION_POWER
    mov dword [esp + 0x00], %1
    cmp ecx, (1 << TIER_%1_ALLOCATION_POWER)
    jle .tier_located
%endmacro

initialize:
    ; Zero out all the control areas
    mov edx, SLAB_BASE + CONTROL_REGION_START

    ; ECX = number of dwords to zero out
    mov ecx, CONTROL_REGION_BYTES_PER_TIER * TIER_COUNT
    add ecx, 3
    shr ecx, 2

.loop:
    cmp ecx, 0
    je .done
    mov dword [edx], 0x00000000
    add edx, 4
    dec ecx
    jmp .loop
.done:
    or dword [SLAB_BASE + ALLOCATOR_FLAGS_LOCATION], ALLOCATOR_INITIALIZED
    ret

allocate_memory:
    push ebp
    mov ebp, esp
    push ebx

    ; Calculate the beginning of that tier's control
    ; region in EDX
    mov edx, [ebp + 0x08]
    imul edx, CONTROL_REGION_BYTES_PER_TIER
    add edx, SLAB_BASE + CONTROL_REGION_START

    ; Walk through that tier and figure out if there
    ; is anything available
    ; ECX = number of allocations in this tier
    mov ecx, [ebp + 0x10]
    ; Double-check that we are dealing with a round
    ; number of dwords here
    test ecx, 0x1f
    jz .bitmask_alignment_ok
    call assert_false
.bitmask_alignment_ok:
    ; ECX = number of dwords
    shr ecx, 5

    ; EAX = counter
    xor eax, eax
.dword_loop:
    cmp eax, ecx
    je .none_available
    cmp dword [edx], 0xffffffff
    jne .found_a_dword_with_room
    add edx, 4
    inc eax
    jmp .dword_loop
.found_a_dword_with_room:
    ; EDX points to the dword, and EAX has the
    ; number of dwords in to the entire block
    ; we are.

    ; Now EAX = number of bits into the block
    ; this dword starts
    shl eax, 5

    ; EBX = bitmask itself
    mov ebx, [edx]
    xor ecx, ecx
.bit_loop:
    cmp ecx, 32
    je .none_available ; impossible until we have race conditions
    test ebx, 0x00000001
    jz .found
    shr ebx, 1
    inc ecx
    jmp .bit_loop
.found:
    ; EAX = number of bits into the region this
    ; dword is; ECX = number of bits into this
    ; dword the space is
    push ecx

    ; First mark the space as allocated now
    mov ebx, 0x1
.reconstruct_bit_loop:
    cmp ecx, 0
    je .reconstruct_done
    shl ebx, 1
    dec ecx
    jmp .reconstruct_bit_loop
.reconstruct_done:
    or [edx], ebx

    pop ecx

    ; Calculate the pointer we'll give back to
    ; the user
    add eax, ecx
    mov ebx, [ebp + 0x0c]
.reconstruct_pointer_loop:
    cmp ebx, 0
    je .reconstruct_pointer_done
    shl eax, 1
    dec ebx
    jmp .reconstruct_pointer_loop
.reconstruct_pointer_done:
    mov edx, [ebp + 0x08]
    shl edx, TIER_ALLOCATION_START_OFFSET_POWER_2
    lea eax, [eax + edx + SLAB_BASE]
    jmp .done

.none_available:
    ; Nothing available!
    xor eax, eax
.done:
    pop ebx
    leave
    ret

malloc:
    push ebp
    mov ebp, esp

    test dword [SLAB_BASE + ALLOCATOR_FLAGS_LOCATION], ALLOCATOR_INITIALIZED
    jnz .already_initialized
    call initialize
.already_initialized:
    ; ECX = size of the memory to allocate
    ; Figure out which tier we need to pull from
    mov ecx, [ebp + 0x08]

    ; TODO: Find a more efficient way to do this
    ; next bit!
    push dword TIER_0_ALLOCATION_COUNT
    push dword TIER_0_ALLOCATION_POWER
    push dword 0
    cmp ecx, (1 << TIER_0_ALLOCATION_POWER)
    jle .tier_located
    check_size_against_tier 1
    check_size_against_tier 2
    check_size_against_tier 3
    check_size_against_tier 4
    check_size_against_tier 5
    check_size_against_tier 6
    check_size_against_tier 7

    ; The size of memory asked for is too big!
    xor eax, eax
    jmp .done
.tier_located:
    call allocate_memory
.done:
    add esp, 12

    leave
    ret

free:
    ret
