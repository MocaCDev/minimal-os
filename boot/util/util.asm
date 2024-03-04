%macro x86_EnterRealMode 0
    [bits 32]
    jmp word 18h:.pmode16         ; 1 - jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in cr0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
    mov ss, ax

    ; 5 - enable interrupts
    sti

%endmacro


%macro x86_EnterProtectedMode 0
    cli

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode


.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

%endmacro

section .text
global x86_Disk_Reset
x86_Disk_Reset:
    [bits 32]

    ; make new call frame
    push ebp             ; save old call frame
    mov ebp, esp          ; initialize new call frame


    x86_EnterRealMode

    mov ah, 0
    mov dl, [bp + 8]    ; dl - drive
    stc
    int 13h

    mov eax, 1
    sbb eax, 0           ; 1 on success, 0 on fail   

    push eax

    x86_EnterProtectedMode

    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret

global check_for_mode
check_for_mode:
    use32
    push ebp 
    mov ebp, esp

    x86_EnterRealMode

    use16
    xor ax, ax

    mov ah, 0x4F
    mov di, vbe_info_block
    int 0x10

    cmp ax, 0x4F
    jne .failed_end

    ; Store `vbe_info_block` at address given to the stub via the
    ; second argument
    mov si, vbe_info_block
    mov di, [ebp + 16]

    ; `vbe_info_block` is 512 bytes in size
    ; 4 (movsd) * 128 (ecx) = 512 bytes
    mov ecx, 128
    rep movsd

.success_end:
    mov ax, word [vbe_info_block.video_modes]
    mov [video_modes_offset], ax

    mov ax, word [vbe_info_block.video_modes + 2]
    mov [video_modes_segment], ax

    mov fs, ax
    mov si, [video_modes_offset]

    mov ax, [ebp + 8]
    mov [VID_MODE_WIDTH], ax
  
    mov ax, [ebp + 10]
    mov [VID_MODE_HEIGHT], ax

    mov ax, [ebp + 12]
    mov [VID_MODE_BPP], al

.get_mode:
    mov dx, [fs:si]
    add si, 0x02

    mov [video_modes_offset], si
    mov [video_mode], dx

    cmp word [video_mode], 0xFFFF
    je .failed_end

    mov ax, 0x4F01
    mov cx, [video_mode]
    mov di, mode_info_block
    int 0x10

    mov ax, [VID_MODE_WIDTH]
    cmp ax, word [mode_info_block.width]
    jne .next

    mov ax, [VID_MODE_HEIGHT]
    cmp ax, word [mode_info_block.height]
    jne .next

    mov al, [VID_MODE_BPP]
    cmp al, byte [mode_info_block.bpp]
    jne .next

    jmp .end
.next:
    mov ax, [video_modes_segment]
    mov fs, ax

    mov si, [video_modes_offset]
    jmp .get_mode

.failed_end:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10

.end:

    ; "Clear" out the memory used to store video mode data
    mov word [VID_MODE_WIDTH], 0x0 
    mov word [VID_MODE_HEIGHT], 0x0 
    mov byte [VID_MODE_BPP], 0x0

    x86_EnterProtectedMode
    use32

    mov esp, ebp
    pop ebp

    xor eax, eax
    mov eax, [video_mode]
    ; In some tutorials, the video mode # will be ored with 0x4000.
    ; I have tested the code without that, and it works indifferently.

    ret

global tryy2
bit16_print_string_info:
    use32
    push ebp
    mov ebp, esp

    x86_EnterRealMode
    use16

  
    mov dx, [ebp + 8]
    call print_hex_word
    mov si, [ebp + 12]
    call print_string
    ;mov ah, 0x0E
    ;mov al, [esi]
    ;int 0x10
    jmp $
.str:
    resb 0x5

global strlen
strlen:
    use32
    push ebp
    mov ebp, esp

    ; Clear `eax` register
    xor eax, eax

    ; Obtain char pointer array
    mov esi, [ebp + 8]

.loop:
  
    ; Load byte from `esi`, test to see if it is zero
    lodsb
    test al, al
    je .end
  
    ; If the byte loaded from `esi` is not zero, increment the length
    mov eax, [.length]
    inc eax
    mov [.length], eax

    ; Repeat until we reach the end of the string
    jmp .loop
.end:

    ; Restore the stack
    mov esp, ebp
    pop ebp

    ; Save the strings length
    mov eax, [.length]

    ret

; Although unlikely, allow for 4-bytes worth of memory to store
; the strings size.
.length: dd 0x0

global enter_real_mode
enter_real_mode:
    use32

    x86_EnterRealMode
    use16

    ret

global enter_protected_mode
enter_protected_mode:
    use16

    x86_EnterProtectedMode
    use32

    ret

global tryy
set_vesa_mode:
    use32
    push ebp
    mov ebp, esp

    x86_EnterRealMode

    use16
    mov dx, [ebp + 8]
    call print_hex_word
    jmp $

    mov ax, 0x4F02
    mov bx, [ebp + 8]
    xor di, di
    int 0x10

    cmp ax, 0x4F
    jne .failed
    jmp .good

.failed:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10

.good:

    x86_EnterProtectedMode
    use32

    mov esp, ebp
    pop ebp

    ret

use16
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

section .data
    ; Explicit video mode information
    video_modes_offset:     dw 0x000
    video_modes_segment:    dw 0x0000
    video_mode:             dw 0x0000

section .rodata
    ; Data for video mode being looked for
    VID_MODE_WIDTH          equ 0x500
    VID_MODE_HEIGHT         equ 0x502
    VID_MODE_BPP            equ 0x504


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


section .text
use16
print_hex_word:
    pusha
    mov cx, 0x04

.loop:
    dec cx

    mov ax, dx
    shr dx, 0x04
    and ax, 0xF

    mov bx, hex
    add bx, 2
    add bx, cx

    cmp ax, 0xA
    jl .set
    add byte [bx], 0x7
.set:
    add byte [bx], al

    cmp cx, 0x00
    je .end
    jmp .loop
.end:
    mov si, hex
    call print_string

.reset_hex:
    mov bx, hex
    add bx, 0x02

.reset_hex_loop:
    cmp byte [bx], 0x0
    jne .set_to_zero
  
    popa
    ret

.set_to_zero:
    mov byte [bx], '0'
    inc bx
    jmp .reset_hex_loop

hex: db '0x0000', 0x0
