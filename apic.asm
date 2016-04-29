align 16, db 0

db 'apic.asm', 0

align 16, db 0

%define MSR_APIC_BASE 0x0000001b
%define APIC_BASE 0xfee00000

%define BOOTSTRAP_PROCESSOR FLAG(8)
%define APIC_GLOBAL_ENABLE FLAG(11)

%define APIC_SOFTWARE_ENABLE FLAG(8)

check_for_apic:
    mov eax, 1
    cpuid
    and edx, 0x200
    jz assert_false
    ; Get the base address of the APIC's
    ; memory-mapped registers
    mov ecx, MSR_APIC_BASE
    rdmsr
    ; We're not prepared for the APIC to be
    ; anywhere other than 0xfee00000, and
    ; expect it to be enabled, and we are
    ; the bootstrap processor
    cmp edx, 0x00000000
    jne assert_false
    cmp eax, APIC_BASE | BOOTSTRAP_PROCESSOR | APIC_GLOBAL_ENABLE
    jne assert_false

    ; Try to enable it?
    mov eax, [APIC_BASE + 0xf0]
    or eax, APIC_SOFTWARE_ENABLE
    mov [APIC_BASE + 0xf0], eax

    ret
