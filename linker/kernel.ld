ENTRY(main)
kernel_physical_address = 0x8400;

SECTIONS
{
  . = kernel_physical_address;

  /* Data is assigned in the second stage bootloader. */
  vesa = 0x5000;

  .text : AT(0x8400)
  {
    *(__start*);
    *(.text*);
  }

  .data :
  {
    *(.bss*);
    *(.data*);
    *(.rodata*);
    *(COMMON*);
  }
}
