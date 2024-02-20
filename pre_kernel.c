extern unsigned char kernel_physical_address[];
extern unsigned char kernel_virtual_address[];
extern "C" void __attribute__((cdecl)) enter_real_mode();

void __attribute__((section("__start"))) main(void)
{
  unsigned char *b = (unsigned char *)0xB8000;
  //b[0] = *kernel_physical_address;
  /* Obtain the number of sectors the kernel occupies from the MBR Partition Table. */ 
  unsigned char *kernel_sectors = (unsigned char *)(0x7C00 + 0x1FA);

  /* Multiply # of sectors by 512 to get the # of bytes occupied by the kernel. */ 
  unsigned short kernel_bytes = kernel_sectors[0] * 512;

  /* Place kernel binary at new address. */
  for(int i = 0; i < kernel_bytes; i++)
    *(kernel_virtual_address + i) = *(kernel_physical_address + i);

  //*kernel_virtual_address = *kernel_physical_address;

  enter_real_mode();

  __asm__("jmp 0x0:0x7f05");
  
  while(1);
}
