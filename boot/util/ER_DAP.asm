use16

section .data
  ; Extended Read Disk Address Packet (DAP)
  extended_read_DAP:
    .size:        db 0x10
    .pad:         db 0x00
    .NOS:         dw 0x00 ; Number Of Sectors (NOS)
    .ADDR:        dd 0x0000
    .LBA:         dq 0x0001 ; Logical Block Address (LBA)

