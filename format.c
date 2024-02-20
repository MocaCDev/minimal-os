#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Program for formatting `bin/kernel.bin` to multiple of 512 bytes (sector-sized blocks). */

int main(int args, char *argv[])
{
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
     * of 512 bytes.
     * */
    size_t pad_size = 0;
    while((kernel_bin_size + pad_size) % 512 != 0)
        pad_size++;

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
