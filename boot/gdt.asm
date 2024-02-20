use16

; Taken from FAMP Protocol because I am too lazy to piece this together again
; based off documention
GDT:
  .null_desc          dq 0x0

            ; 32-bit code segment
            .code32_limit       dw 0xFFFF                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            .code32_base        dw 0                        ; base (bits 0-15) = 0x0
            .code32_base2       db 0                        ; base (bits 16-23)
            .code32_acces       db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            .code32_gran        db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            .code32_base_high   db 0                        ; base high

            ; 32-bit data segment
            .data32_limit       dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            .data32_base        dw 0                        ; base (bits 0-15) = 0x0
            .data32_base2       db 0                        ; base (bits 16-23)
            .data32_access      db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            .data32_gran        db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            .data32_base_high   db 0                       ; base high

            ; 16-bit code segment
            .cod16_limit        dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            .code16_base        dw 0                        ; base (bits 0-15) = 0x0
            .code16_base2       db 0                        ; base (bits 16-23)
            .code16_access      db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            .code16_gran        db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            .code16_base_high   db 0                        ; base high

            ; 16-bit data segment
            .data16_limit       dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            .data16_base        dw 0                        ; base (bits 0-15) = 0x0
            .data16_base2       db 0                        ; base (bits 16-23)
            .data16_access      db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            .data16_gran        db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            .data16_base_high   db 0                        ; base high
GDT_DESC:
  dw GDT_DESC - GDT - 1
  dd GDT

load_gdt:
  in al, 0x92
  or al, 0x02
  out 0x92, al

  cli
  lgdt [GDT_DESC]

  mov eax, cr0
  or eax, 0x01
  mov cr0, eax

  jmp word 0x8:init_protected_mode

use32
init_protected_mode:
  xor ax, ax

  mov ax, 0x10
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax

  ;mov byte [0xB8000], 'A'

  jmp word 0x8:0x8400
