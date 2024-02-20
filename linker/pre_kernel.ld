ENTRY(main)
pre_kernel_physical_address = 0x2000;

SECTIONS
{
  . = pre_kernel_physical_address;

  kernel_virtual_address = 0x20000000;
  kernel_physical_address = 0x8400;

  .text : AT(pre_kernel_physical_address)
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
