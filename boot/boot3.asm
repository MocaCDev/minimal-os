bits 16

section .text
start:
  mov ah, 0x0E
  mov al, 'A'
  int 0x10
  
  ret

jmp $
