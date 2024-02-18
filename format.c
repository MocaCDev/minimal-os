#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Program for formatting `bin/kernel.bin` to multiple of 512 bytes (sector-sized blocks). */

int main(int args, char *argv[])
{
  FILE *kernel_bin = fopen("bin/kernel.bin", "rb");
  if(!kernel_bin)
  {
    fprintf(stderr, "Error opening Kernel Binary.\n");
    exit(EXIT_FAILURE);
  }

  fseek(kernel_bin, 0, SEEK_END);
  size_t kernel_bin_size = ftell(kernel_bin);
  fseek(kernel_bin, 0, SEEK_SET);

  fclose(kernel_bin);

  size_t pad_size = 0;
  while((kernel_bin_size + pad_size) % 512 != 0)
    pad_size++;

  printf("%ld", pad_size);

  char *pad = (char *)calloc(pad_size, sizeof(*pad));
  memset((void *)pad, 0, pad_size);

  kernel_bin = fopen("bin/kernel.bin", "a");
  fwrite((const void *)pad, pad_size, sizeof(*pad), kernel_bin);
  fclose(kernel_bin);

  return 0;
}
