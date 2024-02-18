use16

; Taken from FAMP Protocol because I am too lazy to piece this together again
; based off documention
GDT:
  .null_desc        dq 0x0

  ; 32-bit code segment
  .code32_limit     dw 0xFFFF
  .code32_base      dw 0x0000
  .code32_base2     db 0x00
  .code32_access    db 10011010b
  .code32_gran      db 11001111b
  .code32_base_high db 0x00

  ; 32-bit data segment
  .data32_limit     dw 0xFFFF
  .data32_base      dw 0x0000
  .data32_base2     db 0x00
  .data32_access    db 10010010b
  .data32_gran      db 11001111b
  .data32_base_high db 0x00

  ; 16-bit code segment
  .code16_limit     dw 0xFFFF
  .code16_base      dw 0x0000
  .code16_base2     db 0x00
  .code16_access    db 10011010b
  .code16_gran      db 00001111b
  .code16_base_high db 0x00

  ; 16-bit data segment
  .data16_limit     dw 0xFFFF
  .data16_base      dw 0x0000
  .data16_base2     db 0x00
  .data16_access    db 10010010b
  .data16_gran      db 00001111b
  .data16_base_high db 0x00

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
