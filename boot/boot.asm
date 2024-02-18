; MBR - First Sector
bits 16

; Following https://wiki.osdev.org/FAT 
; Got help from https://stackoverflow.com/questions/43786251/int-13h-42h-doesnt-load-anything-in-bochs
jmp 0x0:start
nop

section .rodata
  ; FAT File System Data
  OEM_ID:     db 'EZNOS0.1'           ; EZNotes Operating System 0.1 (EZNOS0.1)
  BPS:        dw 0x200                ; 512 bytes per sector
  SPC:        db 0x01                 ; 1 sector per cluster (SPC)
  RESS:       dw 0x03                 ; 2 reserved sectors (RESS); bootloader(1 sector) and second stage(2 sectors)
  FATs:       db 0x02                 ; Just following the tutorial which states "...often this value is 2"
  NORDE:      dw 0x01                 ; 1 root directory entry for now (NODE = Number Of Root Directory Entries)
  TSC:        dw 0xB40                ; Total sectors, in accordance to https://github.com/nanobyte-dev/nanobyte_os/blob/master/src/bootloader/stage1/boot.asm#L31
  MDT:        db 0xF0                 ; Media Descriptor Type. See https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#BPB20_OFS_0Ah (0xF0)
  SPF:        dw 0x01                 ; 1 sector per fat (SPF)
  SPT:        dw 0x12                 ; 18 sectors per track (SPT). See https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#BPB20_OFS_0Ah (0xF0)
  NOH:        dw 0x02                 ; 2 heads (NOH = Number Of Head). See https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#BPB20_OFS_0Ah (0xF0)
  LSC:        dd 0x0000               ; Set to zero sinse `TSC` is set. If `TSC` is not set, `LSC` will be set. (LSC = Large Sector Count)

  ; FAT32 Specific
  F32_SPF:    dd 0x0000               ; FAT32 Specific Sectors Per Fat (SPF). Set to zero following https://github.com/nanobyte-dev/nanobyte_os/blob/master/src/bootloader/stage1/boot.asm#L40
  F32_FLAGS:  dw 0x0000               ; FAT32 Flags. Set to zero following https://github.com/nanobyte-dev/nanobyte_os/blob/master/src/bootloader/stage1/boot.asm#L41
  F32_VN:     dw 0x0000               ; FAT32 Version Number (VN). Set to zero following https://github.com/nanobyte-dev/nanobyte_os/blob/master/src/bootloader/stage1/boot.asm#L42
  F32_RDC:    dd 0x0002               ; FAT32 number of Root Directory Clusters (RDC). Set to two following https://wiki.osdev.org/FAT
  F32_FISSN:  dw 0x0000               ; FAT32 FSInfo Structure Sector Number (FISSN). Set to zero following https://github.com/nanobyte-dev/nanobyte_os/blob/master/src/bootloader/stage1/boot.asm#L44
  F32_BBS:    dw 0x0000               ; FAT32 Backup Boot Sector (BBS). Set to zero following https://github.com/nanobyte-dev/nanobyte_os/blob/master/src/bootloader/stage1/boot.asm#L45
  F32_RES:    times 12 db 0           ; FAT32 12-bytes reserved (RES)
  F32_DN:     db 0x80                 ; FAT32 Drive Number (DN). 0x80 for Hard Disk, 0x00 for Floppy Disk
  F32_RES2:   db 0x0                  ; Flags in Windows NT. Reserved otherwise in accordance to https://wiki.osdev.org/FAT
  F32_SIG:    db 0x29                 ; FAT32 Signature (0x28 or 0x29 in accordance to https://wiki.osdev.org/FAT)
  F32_VID:    db 0xA, 0xE, 0xDE, 0xED ; FAT32 Volume ID (VID) "Serial" number (used for tracking volumes between computers in accordance to https://wiki.osdev.org/FAT)
  F32_VLS:    db 'EZNotes OS '        ; FAT32 Volume Label String (VLS)
  F32_SID:    db 'FAT32   '           ; FAT32 System Id String (SID)

  VesaVidMode_Setup:
    width         dw 0x640
    height        dw 0x384
    bpp           dw 0x110
  
section .bss
  struc mbr_partition_table_entry
    .is_bootable          resb 0x01 
    .starting_head        resb 0x01 
    ; First 6 bits = Starting sector 
    ; Last 10 bits = Starting cylinder
    .starting_sector      resw 0x01       ; Will be left alone
    .ID                   resb 0x01
    .ending_head          resb 0x01
    ; First 6 bits = Ending sector
    ; Last 10 bits = Ending cylinder
    .ending_sector        resw 0x01       ; Will be left alone
    .LBA                  resd 0x01
    .total_sectors        resd 0x01
  endstruc

  ; %1 = Partition entry #
  ; %2 = Is bootable (0x80 = bootable, 0x0 = not bootable)
  ; %3 = Starting sector
  ; %4 = Partition ID (0x0A = MBR, 0x0B = Second Stage, 0x0C = Kernel, 0x0D = Unused, 0x0F = Filesystem)
  ; %5 = Ending sector
  ; %6 = LBA (should resemble %5)
  ; %7 = Total sectors that the program takes up
  %macro create_partition_entry       7
    mbr_partition_table_entry%+%1:
      istruc mbr_partition_table_entry
        at mbr_partition_table_entry.is_bootable,     db %2
        at mbr_partition_table_entry.starting_head,   db 0x0
        at mbr_partition_table_entry.starting_sector, dw %3
        at mbr_partition_table_entry.ID,              db %4
        at mbr_partition_table_entry.ending_head,     db 0x0
        at mbr_partition_table_entry.ending_sector,   dw %5
        at mbr_partition_table_entry.LBA,             dd %6
        at mbr_partition_table_entry.total_sectors,   dd %7
      iend
  %endmacro
  
; Second stage check ID (to make sure we read in the right program)
%define SS_CHECK_ID     0xEBED

section .text
  global start

  start:
    cli
    cld 
    sti 

    xor ax, ax
    mov ds, ax
    mov es, ax
    
    cli
    mov ss, ax
    mov sp, 0x7c00
    mov bp, sp 
    sti 

    ; Set the Drive Number to be used to read sectors
    mov [F32_DN], dl

    ; See https://www.delorie.com/djgpp/doc/rbinter/id/12/7.html

    ; Checking for BIOS extension support
    mov ah, 0x41
    mov bx, 0x55AA

    ; Explicitly set the carry flag so we know whether or not extensions are supported
    stc
    int 0x13

    ; If the carry flag is still set, extensions are not supported
    jc  no_extensions_error

    ; If `bx` is 0xAA55, extensions are supported. `bx` has to be 0xAA55
    cmp bx, 0xAA55
    jnz no_extensions_for_drive_error
  
  .read:
    ; Configure second stage addres 
    mov ax, second_stage_segment
  
    ; segment:offset follows the following formula: segment * 16 + offset 
    imul ax, 0x10
    add ax, second_stage_offset

    ; Second stage has 2 sectors as described in the Second Partition Entry
    mov cx, word [0x7C00 + 0x1DA]

    mov [extended_read_DAP.ADDR], eax
    mov [extended_read_DAP.NOS], cx

    ; Get the according LBA in alliance with the program and assign it
    mov cx, word [0x7C00 + 0x1D6]
    mov [extended_read_DAP.LBA], cx

    ; Load second stage based on extended read Disk Address Paket (DAP)
    mov si, extended_read_DAP
    mov ah, 0x42
    int 13h
    jc failed_to_read

    ; Make sure we read in the right program
    mov si, [extended_read_DAP.ADDR]
    mov ax, [si + 5]

    cmp ax, SS_CHECK_ID
    jne invalid_program_read

    ; Jump to second stage bootloader to setup VESA video mode and obtain memory map
    jmp 0x7E0:0x0;second_stage_segment:second_stage_offset

    ; Hopefully, we never get here
    jmp 0xFFFF:0x0000     ; "reboot"

    cli
    hlt

    ; We should never get here
    jmp $

  failed_to_read:
    mov si, read_sectors_error_msg
    call print_string

    cli
    hlt
    
    jmp $

jmp $

%include "boot/util/ER_DAP.asm"

section .text
  ; int 0x13 extensions not supported
  no_extensions_error:
    mov si, no_extensions_error_msg
    call print_string

    cli
    hlt

    jmp $

  ; int 0x13 extensions not supported with drive #
  no_extensions_for_drive_error:
    mov si, no_extensions_for_drive_error_msg
    call print_string

    cli
    hlt

    jmp $

  invalid_program_read:
    mov si, invalid_program_error_msg
    call print_string

    cli
    hlt

    jmp $

  ; Taken from stackoverflow because I am lazy
  print_string:
    push ax
    push si
    mov ah, 0Eh       ; int 10h 'print char' function

  .repeat:
    lodsb             ; Get character from string
    test al, al
    je .done      ; If char is zero, end of string
    int 10h           ; Otherwise, print it
    jmp .repeat
  .done:
    pop si
    pop ax
    ret

section .rodata
  ; Second stage address information
  second_stage_segment      equ 0x07E0
  second_stage_offset       equ 0x0000


section .rodata
  ; Error messages to plausibly print throughout the program
  no_extensions_for_drive_error_msg:db 'Extensions not supported for drive 0x80', 0x00
  no_extensions_error_msg:          db 'Extensions not supported.', 0x00
  read_sectors_error_msg:           db 'Failed to read sectors.', 0x00
  invalid_program_error_msg:        db 'Invalid program read into memory.', 0x00

  ; 35 bytes of padding to locate first MBR Partition Table Entry 446 bytes into the
  ; MBR
  times 49 db 0x0

  ; MBR
  create_partition_entry 1, 0x80, 0x00, 0x0A, 0x1, 0x0, 0x1
  
  ; Second Stage (LBA = 0x1, program starts at end of first sector)
  create_partition_entry 2, 0x00, 0x01, 0x0B, 0x3, 0x1, 0x2

  ; Kernel (LBA = 0x3, program starts at end of third sector)
  create_partition_entry 3, 0x00, 0x03, 0x0C, 0x4, 0x3, 0x1

  ; Unused
  create_partition_entry 4, 0x00, 0x00, 0x0D, 0x0, 0x0, 0x0


; "Magic" number 0xAA55
section .magic