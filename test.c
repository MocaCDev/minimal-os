extern "C" void __attribute__((cdecl)) x86_Disk_Reset();
extern "C" void __attribute__((cdecl)) t();

void testing()
{
  x86_Disk_Reset();
}

static unsigned char *d = (unsigned char *)0xB8000;

void __attribute__((section("__start"))) main(void)
{
  //x86_Disk_Reset();
  //t();
  //testing();
  t();

  //d[0] = 'G';
  while(1);
}
