ENTRY(main)
kernel_physical_address = 0x8400;

SECTIONS
{
  . = kernel_physical_address;

  /* Data is assigned in the second stage bootloader. */
  vesa = 0x5000;
  
  .text : AT(kernel_physical_address)
  {
    *(.text);
  }

  .data :
  {
    *(.bss*);
    *(.data*);
    *(.rodata*);
    *(COMMON*);
  }
}
