use16

jmp 0x0:start

section .text
  start:
    xor ax, ax
    mov es, ax
    mov ds, ax

    mov ss, ax
    mov sp, 0x7C00

    push es
    push word .after

    retf

  .after:
    mov [ebr_drive_number], dl

jmp $

section .data
  ebr_drive_number:   db 0x0
