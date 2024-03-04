#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Program for formatting `bin/kernel.bin` to multiple of 512 bytes (sector-sized blocks). */
#define STARTING_LBA      0x03

int main(int args, char *argv[])
{
    /* `fmbr` = (F)ormat (M)aster (B)oot (R)ecord. */ 
    if(strcmp(argv[1], "fmbr") == 0)
    {
        /* Obtain pre kernel and kernel binary sizes. */ 
        FILE *kernel_bin = fopen("bin/kernel.bin", "rb");
        FILE *pre_kernel_bin = fopen("bin/pre_kernel.bin", "rb");

        if(!pre_kernel_bin)
        {
            fprintf(stderr, "Error opening pre kernel binary.\n");

            exit(EXIT_FAILURE);
        }

        if(!kernel_bin)
        {
            fprintf(stderr, "Error opening kernel binary.\n");

            exit(EXIT_FAILURE);
        }

        size_t pre_kernel_bin_size = 0;
        size_t kernel_bin_size = 0;

        fseek(kernel_bin, 0, SEEK_END);
        kernel_bin_size = ftell(kernel_bin);
        fseek(kernel_bin, 0, SEEK_SET);
        fclose(kernel_bin);

        fseek(pre_kernel_bin, 0, SEEK_END);
        pre_kernel_bin_size = ftell(pre_kernel_bin);
        fseek(pre_kernel_bin, 0, SEEK_SET);
        fclose(pre_kernel_bin);

        printf("# of sectors for kernel: %ld\n# of sectors for pre kernel: %ld\n",
               kernel_bin_size / 512,
               pre_kernel_bin_size / 512);

        FILE *boot_format = fopen("boot_format", "rb");

        if(!boot_format)
        {
            fprintf(stderr, "MBR format was not found.\n");

            exit(EXIT_FAILURE);
        }

        fseek(boot_format, 0, SEEK_END);
        size_t boot_format_size = ftell(boot_format);
        fseek(boot_format, 0, SEEK_SET);

        if(boot_format_size < 1)
        {
            fprintf(stderr, "No format found in `boot_format`.\n");

            exit(EXIT_FAILURE);
        }

        unsigned char *format = (unsigned char *)calloc(boot_format_size, sizeof(*format));
        
        /* `cformat` = (C)ompleted (F)ormat. */ 
        unsigned char *cformat = (unsigned char *)calloc(boot_format_size + 20, sizeof(*cformat));

        fread((void *)format, sizeof(*format), boot_format_size, boot_format);
        fclose(boot_format);

        sprintf((char *)cformat, (char *)format,
            STARTING_LBA + (pre_kernel_bin_size / 512),
            pre_kernel_bin_size / 512,
            STARTING_LBA + (pre_kernel_bin_size / 512),
            STARTING_LBA + (pre_kernel_bin_size / 512),
            kernel_bin_size / 512);
        
        FILE *boot_file = fopen("boot/boot.asm", "wb");

        if(!boot_file)
        {
            fprintf(stderr, "Could not open `boot/boot.asm` to write MBR.\n");

            exit(EXIT_FAILURE);
        }

        fwrite((const void *)cformat, sizeof(*cformat), strlen((const char *)cformat), boot_file);
        fclose(boot_file);

        return 0;
    }

    FILE *kernel_bin = fopen(argv[1], "rb");

    if(!kernel_bin)
    {
        fprintf(stderr, "Error opening `%s`\n", argv[1]);
        exit(EXIT_FAILURE);
    }

    /* Obtain the size of the binary so we can then decipher how much padding is needed
     * to make the binary a multiple of 512 bytes.
     * */
    fseek(kernel_bin, 0, SEEK_END);
    size_t kernel_bin_size = ftell(kernel_bin);
    fseek(kernel_bin, 0, SEEK_SET);

    /* This will be a useful "warning" to let us know whether there is a plausible
     * problem when compiling/assembling.
     * */
    if(kernel_bin_size <= 1)
        fprintf(stdout, "Majority of `%s` will be padded.\n", argv[1]);

    fclose(kernel_bin);

    /* Decipher the amount of bytes we need to add to make the binary file a multiple
     *
     * of 512 bytes.
     * */
    size_t pad_size = 0;
    while((kernel_bin_size + pad_size) % 512 != 0)
        pad_size++;

    printf("Padding %ld bytes for `%s`.\n\t%ld + %ld = %ld (%ld sectors)\n",
      pad_size, argv[1],
      pad_size, kernel_bin_size, pad_size + kernel_bin_size,
      (pad_size + kernel_bin_size) / 512);

    /* Allocate bytes for padding. 
     * `calloc` should zero-out all the memory allocated, however we will be explicit
     * and manually set each index of `pad` to zero with `memset`.
     * */
    char *pad = (char *)calloc(pad_size, sizeof(*pad));
    memset((void *)pad, 0, pad_size);

    /* Open the binary file in "write-append" mode (a+b) and write the padding */
    kernel_bin = fopen(argv[1], "a+b");
    fwrite((const void *)pad, pad_size, sizeof(*pad), kernel_bin);
    fclose(kernel_bin);

    free((void *)pad);

    return 0;
}
