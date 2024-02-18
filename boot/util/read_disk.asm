use16

read_disk:
  ; Configure segment:offset address
  imul cx, 0x10
  add cx, ax

  ; Obtain # of sectors for program
  ; `si` will be set to a memory location referencing # of sectors via one of the MBR
  ; Partition Table Entries
  lodsw

  mov [extended_read_DAP.ADDR], cx
  mov [extended_read_DAP.NOS], ax

  mov si, di
  lodsb

  mov byte [extended_read_DAP.LBA], al

  ; Check to see if extensions are enabled
  mov ah, byte [0x500]
  cmp ah, 0x00 
  je .no_extension

  mov si, extended_read_DAP
  mov ah, 0x42
  int 0x13
  jc .failed

  ret
.no_extension:
  xor bx, bx
  mov es, bx
  mov bx, [extended_read_DAP.ADDR]

  mov ah, 0x02
  mov al, [extended_read_DAP.NOS]
  mov ch, 0x00
  mov cl, [extended_read_DAP.LBA]
  inc cl
  mov dh, 0x00
  mov dl, 0x00

  ;stc
  int 0x13
  jc .failed 

  ret
.failed:
  mov si, failed_to_read
  call print_string

  cli
  hlt

  jmp $

section .rodata
  failed_to_read: db 'Failed to read sectors for program', 0x0
