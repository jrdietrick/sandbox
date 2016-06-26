align 16, db 0

db 'rtc.asm', 0

align 16, db 0

%define RTC_COMMAND_PORT 0x70
%define RTC_DATA_PORT (RTC_COMMAND_PORT + 1)

rtc_ticks: dd 0

rtc_init:
    ; Set up the real-time clock (IRQ 8)
    mov al, 0x0a
    out RTC_COMMAND_PORT, al
    mov al, 0x2f
    out RTC_DATA_PORT, al
    mov al, 0x0b
    out RTC_COMMAND_PORT, al
    mov al, 0x40
    out RTC_DATA_PORT, al

    push 8
    call enable_irq
    add esp, 4

rtc_clear:
    mov al, 0x0c
    out RTC_COMMAND_PORT, al
    in al, RTC_DATA_PORT
    ret

rtc_sleep:
    ; EAX = number of ticks to wait
    mov eax, [esp + 0x04]
    ; ECX = starting tick count
    mov ecx, [rtc_ticks]

.spin:
    mov edx, [rtc_ticks]
    sub edx, ecx
    cmp edx, eax
    jge .break
    hlt
    jmp .spin

.break:
    ret

rtc_tick:
    pushad
    ; Acknowledge the RTC tick
    call rtc_clear
    ; Send the EOI to the PIC
    push dword 8
    call send_eoi
    add esp, 4
    popad
    iret
