ENTRY(start)
OUTPUT_FORMAT(elf32-i386)
second_stage_bootloader_phys_addr = 0x7E00;

SECTIONS
{
  . = second_stage_bootloader_phys_addr;

  .text :
  {
     *(.text);
  }

  .data :
  {
    *(.data);
  }

  .rodata :
  {
    *(.rodata);
  }

  .bss :
  {
    *(.bss);
  }

  .end : AT(0x81FF)
  {
    *(.end);
    BYTE(0x0);
  }
}
