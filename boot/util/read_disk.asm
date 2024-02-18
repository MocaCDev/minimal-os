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
  lodsw

  mov ax, 0x03
  mov [extended_read_DAP.LBA], ax

  mov si, extended_read_DAP
  mov ah, 0x42
  int 0x13
  jc .failed

  ret
.failed:
  mov ah, 0x0E
  mov al, 't'
  int 0x10

  cli
  hlt

  jmp $
