use16

jmp 0x0:start

CHECK_ID:     dw 0xEBED

; MBR Partition Table Entry describing the kernel
%define KERNEL_ENTRY      0x7C00 + 0x1BE + 32

section .text
  global start
  
  start:
    ; Get VESA video mode information
    xor ax, ax
    mov es, ax

    ; Read in the kernel
    mov cx, kernel_segment
    mov ax, kernel_offset
    mov si, 0x7C00 + 0x1EA
    mov di, 0x7C00 + 0x1E6
    call read_disk

    ; Reset the stack to grow downwards from the current program
    cli
    mov sp, 0x7E00
    mov bp, 0x7E00
    sti

    ; Clear out `ax` register, otherwise `AH = 0x4F, int 0x10` will fail
    xor ax, ax
     
    mov ah, 0x4F 
    mov di, vbe_info_block
    int 0x10

    ; Assign `si` to the error message that will be printed in `failed`
    ; if the operation failed
    mov si, failed_to_get_super_vga_information

    ; AL = 0x4F if function is supported
    ; AH = 0x00 on success overall
    cmp ax, 0x4F
    jne failed

    mov ax, word[vbe_info_block.video_modes]
    mov [video_modes_offset], ax

    mov ax, word[vbe_info_block.video_modes + 2]
    mov [video_modes_segment], ax

    mov fs, ax
    mov si, [video_modes_offset]

    ; Get the width, height and bits per pixel from the MBR
    push si   ; Save `si`, don't know what it has but we want to keep its value safe
    mov si, 0x600;0x12B

    ; Obtain the width from the address
    lodsw
    mov [VID_MODE_WIDTH], ax

    ; Obtain the height from the address
    lodsw
    mov [VID_MODE_HEIGHT], ax

    ; Obtain the BPP from the address
    lodsb
    mov [VID_MODE_BPP], al
    pop si    ; Restore `si` to its previous state prior to obtaining wanted width/height and bpp from MBR
    
    ; Get the Vesa video mode
    call find_mode
    jmp go_to_kernel
    
    jmp $
  .f:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10

    cli
    hlt

  go_to_kernel:
    in al, 0x92
    or al, 0x02 
    out 0x92, al 

    cli
    lgdt [GDT_DESC]

    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

    jmp word 0x8:init_pm

  find_mode:
    mov dx, [fs:si]
    add si, 2 
    
    mov [video_modes_offset], si 
    mov [video_mode], dx

    ; If `0xFFFF` is reached, we can safely assume the video mode we want has not been found
    cmp word[video_mode], 0xFFFF
    je .end

    mov ax, 0x4F01
    mov cx, [video_mode]
    mov di, mode_info_block
    int 0x10

    mov si, no_vesa_video_mode_support

    mov ax, [VID_MODE_WIDTH]
    cmp ax, word [mode_info_block.width]
    jne .next

    mov ax, [VID_MODE_HEIGHT]
    cmp ax, word [mode_info_block.height]
    jne .next

    mov al, [VID_MODE_BPP]
    cmp al, byte [mode_info_block.bpp]
    jne .next
    
    mov ax, 0x4F02
    mov bx, [video_mode]
    or bx, 0x4000
    xor di, di 
    int 0x10

    mov si, failed_setting_mode

    cmp ax, 0x4F
    jne failed

    ret
  
  .next:
    mov ax, [video_modes_segment]
    mov fs, ax

    mov si, [video_modes_offset]
    jmp find_mode

  .end:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10

    cli
    hlt

    jmp $

  failed:
    ; `si` should be set prior to `failed` being called
    call print_string

    cli 
    hlt 

    jmp $

  use32
  init_pm:
    xor ax, ax

    mov ax, 0x10
    mov es, ax
    mov ds, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; This will do for now
    ; Grow the stack downward from 0x90000
    mov esp, 0x90000
    mov ebp, esp

    ; Store the Vesa Mode data at address 0x5000 so it can be accessed
    ; by the kernel
    mov esi, mode_info_block
    mov edi, 0x5000
    mov ecx, 64
    rep movsd

    jmp word 0x8:0x8400

    ; Hopefully we never get here
    jmp 0xFFFF:0x0000

    ; We should never get here
    jmp $

jmp $

; Made global here for `read_disk`
section .text
  global print_string

%include "boot/gdt.asm"
%include "boot/util/read_disk.asm"
%include "boot/util/ER_DAP.asm"

section .rodata
  ; Kernel address information
  kernel_segment        equ 0x0840
  kernel_offset         equ 0x0000

  ; Error messages to plausibly be printed throughout the program
  done_message:                         db 'All Done', 0x00
  no_vesa_video_mode_support:           db 'No Vesa Support For Mode Wanted', 0x00
  failed_to_get_super_vga_information:  db 'Failed to get SuperVGA Information via AX=0x4F00, int 0x10', 0x00
  failed_setting_mode:                  db 'Failed setting Vesa Video Mode via AX=0x4F02, int 0x10', 0x00

section .text
  print_hex_word:
    push bp
    mov bp, sp      ; BP=SP, on 8086 can't use sp in memory operand
    push dx         ; Save all registers we clobber
    push cx
    push bx
    push ax

    mov cx, 0x0404  ; CH = number of nibbles to process = 4 (4*4=16 bits)
                    ; CL = Number of bits to rotate each iteration = 4 (a nibble)
    mov dx, [bp+4]  ; DX = word parameter on stack at [bp+4] to print
    mov bx, [bp+6]  ; BX = page / foreground attr is at [bp+6]

  .loop:
    rol dx, cl      ; Roll 4 bits left. Lower nibble is value to print
    mov ax, 0x0e0f  ; AH=0E (BIOS tty print),AL=mask to get lower nibble
    and al, dl      ; AL=copy of lower nibble
    add al, 0x90    ; Work as if we are packed BCD
    daa             ; Decimal adjust after add.
                    ;    If nibble in AL was between 0 and 9, then CF=0 and
                    ;    AL=0x90 to 0x99
                    ;    If nibble in AL was between A and F, then CF=1 and
                    ;    AL=0x00 to 0x05
    adc al, 0x40    ; AL=0xD0 to 0xD9
                    ; or AL=0x41 to 0x46
    daa             ; AL=0x30 to 0x39 (ASCII '0' to '9')
                    ; or AL=0x41 to 0x46 (ASCII 'A' to 'F')
    int 0x10        ; Print ASCII character in AL
    dec ch
    jnz .loop       ; Go back if more nibbles to process

    pop ax          ; Restore registers
    pop bx
    pop cx
    pop dx
    pop bp
    ret

  ; Taken from stackoverflow because I am lazy
  print_string:
    push ax
    push si
    mov ah, 0x0E       ; int 10h 'print char' function

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

section .bss
  ; Vesa Info "Structure"
  vbe_info_block:
	  .vbe_signature:			          resb 0x04 ; Should be "VESA"
	  .vbe_version:			            resw 0x01 ;dw 0x0
	  .oem_string_pointer:		      resd 0x01
	  .capabilities:			          resd 0x01
	  .video_modes:			            resd 0x01
	  .total_memory:			          resw 0x01
	  .oem_software_rev:		        resw 0x01
	  .oem_vendor_name_pointer:	    resd 0x01
	  .oem_product_name_pointer:	  resd 0x01
	  .oem_product_revision_pointer:resd 0x01
	  .reserved:	                  resb 222;times 222 db 0
	  .oem_data:	                  resb 256;times 256 db 0

  mode_info_block:
	  .attributes:                  resw 0x01	; 0-2 byte
	  .window_a:		                resb 0x01	; 2-3 byte
	  .window_b:		                resb 0x01	; 3-4 byte
	  .granularity:		              resw 0x01	; 4-6 byte
	  .window_size:		              resw 0x01	; 6-8 byte
	  .segment_a:		                resw 0x01	; 8-10 byte
	  .segment_b:		                resw 0x01	; 10-12 byte
	  .win_func_ptr:		            resd 0x01	; 12-16 byte
	  .pitch:			                  resw 0x01	; 16-18 byte
	  .width:			                  resw 0x01	; 18-20 byte
	  .height:		                  resw 0x01	; 20-22 byte
	  .w_char:		                  resb 0x01	; 22-23 byte
	  .y_char:		                  resb 0x01	; 23-24 byte
	  .planes:		                  resb 0x01	; 24-25 byte
	  .bpp:			                    resb 0x01	; 25-26 byte
  	.banks:			                  resb 0x01	; 26-27 byte
	  .memory_model:		            resb 0x01	; 27-28 byte
  	.bank_size:		                resb 0x01	; 28-29 byte
	  .image_pages:		              resb 0x01	; 29-30 byte
	  .reserved1:		                resb 0x01	; 30-31 byte
	  .red_mask_size:		            resb 0x01	; 31-32 byte
	  .red_field_pos:		            resb 0x01	; 32-33 byte
	  .green_mask_size:	            resb 0x01	; 33-34 byte
	  .green_field_pos:	            resb 0x01	; 34-35 byte
	  .blue_mask_size:	            resb 0x01	; 35-36 byte
	  .blue_field_pos:	            resb 0x01	; 36-37 byte
	  .reserved_mask_size:	        resb 0x01	; 37-38 byte
	  .reserved_field_pos:	        resb 0x01	; 38-39 byte
	  .direct_color_mode_info:      resb 0x01	; 39-40 byte
	  .physical_base_ptr:	          resd 0x01	; 40-44 byte
	  .reserved2:		                resd 0x01	; 44-48 byte
	  .reserved3:		                resw 0x01	; 48-50 byte
	  .linear_bytes_psl:	          resw 0x01	; 50-52 byte
	  .bank_number_of_ip:	          resb 0x01	; 52-53 byte
	  .linear_number_of_ip:	        resb 0x01	; 53-54 byte
	  .linear_red_mask_size:	      resb 0x01	; 54-55 byte
	  .linear_red_field_pos:	      resb 0x01	; 55-56 byte
	  .linear_green_mask_size:      resb 0x01	; 56-57 byte
	  .linear_green_field_pos:      resb 0x01	; 57-58 byte
	  .linear_blue_mask_size:       resb 0x01	; 58-59 byte
	  .linear_blue_field_pos:       resb 0x01	; 59-60 byte
	  .linear_res_mask_sie:         resb 0x01	; 60-61 byte
	  .linear_res_field_pos:	      resb 0x01	; 61-62 byte
	  .max_pixel_clock:	            resd 0x01	; 62-66 byte
  	.reserved4:                   resb 190  ; times 190 db 0

section .rodata
  ; Data for video mode being looked for
  VID_MODE_WIDTH          equ 0x500
  VID_MODE_HEIGHT         equ 0x502
  VID_MODE_BPP            equ 0x504

section .data
  ; Explicit video mode information
  video_modes_offset:     dw 0x000
  video_modes_segment:    dw 0x0000
  video_mode:             dw 0x0000

; Letting linker know this is the end
; Also here so the linker can grab any plausible code that may exist
; within this section
section .end
