ENTRY(start)
OUTPUT_FORMAT(elf32-i386)
bootloader_phys_addr = 0x7C00;

SECTIONS
{
  . = bootloader_phys_addr;

  .text :
  {
    *(.text);
  }

  .data :
  {
    *(.data);
  }
  
  .bss :
  {
    *(.bss);
  }

  /* We want the RODATA to be at the end of the binary file. */
  .rodata :
  {
    *(.rodata);
  }

  .magic : AT(0x7DFE)
  {
    SHORT(0xAA55);

    /* Just good practice. */
    *(.magic);
  }
}
