use16

org 0x7c00

    cli
    xor eax, eax
    mov ss, ax
    mov es, ax
    mov ds, ax
    mov sp, 0x7c00
    sti

    call clear_screen

    mov bp, sp

    ; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH.3D42h:_Extended_Read_Sectors_From_Drive
    ; Read from sector 0x0000000000000001
    push dword 0x00000000
    push dword 0x00000001
    ; Load into memory at 0x0000:0x8000
    push word 0x0000
    push word 0x8000
    ; Read 16 sectors (8KB)
    push word 16
    ; This struct is 16 bytes
    push word 16

    ; DL should contain the drive index already -- be careful not to stomp before this!
    ; Should we just be stashing it somewhere?
    mov si, sp
    mov ah, 0x42
    int 0x13

    ; If the carry flag is set, something went wrong.
    jc read_sectors_error

    ; Fix the stack
    mov sp, bp

    ; Read up to 4 4096-byte programs
    ; from the "filesystem" in to 0xc000
    push dword 0x00000000
    push dword 0x00000011
    push word 0x0000
    push word 0xc000
    push word 32
    push word 16
    mov si, sp
    mov ah, 0x42
    int 0x13

    ; We don't care about errors for this
    ; one, it's a best-effort attempt

    mov sp, bp

    ; Jump to boot32.asm
    jmp 0x0000:LOAD_LOCATION

read_sectors_error:
    mov esi, string_read_sectors_error
    call display_message
    jmp halt

clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

display_message:
    push eax

.loop:
    lodsb
    cmp al, 0
    je .done
    push si
    mov ah, 0x0e
    int 0x10
    pop si
    jmp .loop

.done:
    pop eax
    ret

halt:
    hlt
    jmp halt

string_read_sectors_error: db 'FATAL: Could not read sectors from drive!', 0

times 446-($-$$) db 0

; MBR table
db 0x80, 0x00, 0x01, 0x00, 0xeb, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

db 0x55, 0xaa
