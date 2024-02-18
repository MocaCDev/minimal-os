#include "include/io.hpp"
typedef unsigned char		uint8;
typedef char			int8;
typedef unsigned short		uint16;
typedef short			int16;
typedef unsigned int		uint32;
typedef int			int32;
typedef unsigned long long	uint64, size_t;
typedef long long		int64;

#include <io.hpp>

typedef struct VesaInfoBlock
{
	uint16		attributes;
	uint8		window_a;
	uint8		window_b;
	uint16		gran;
	uint16		window_size;
	uint16		seg_a;
	uint16		seg_b;
	uint32		win_func_ptr;
	uint16		pitch;
	uint16		width;
	uint16		height;
	uint8		w_char;
	uint8		y_char;
	uint8		planes;
	uint8		bpp;
	uint8		banks;
  uint8		memory_model;
	uint8		bank_size;
	uint8		image_pages;
	uint8		reserved1;
	uint8		red_mask;
	uint8		red_pos;
	uint8		green_mask;
	uint8		green_pos;
	uint8		blue_mask;
	uint8		blue_pos;
	uint8		reserved_mask;
	uint8		reserved_pos;
	uint8		direct_color_attributes;
	uint32		framebuffer;
	uint32		off_screen_mem_off;
	uint16		off_screen_mem_size;
	uint8		reserved2[206];
} __attribute__((packed)) Vesa_Info_Block;

Vesa_Info_Block *v_mode = (Vesa_Info_Block *)0x5000;

#define make_color(r,g,b) r*65536 + g*256 + b
#define buffer v_mode->framebuffer

void __attribute__((section("__start"))) main(void)
{
  unsigned char *f = (unsigned char *)0xB8000;

  f[0] = 'D';

  uint32 *buf = (uint32 *) buffer;

  //inp_byte(0x40);
  //outp_byte(0xE9, 'H');

  for(int i = 0; i < v_mode->width * v_mode->height; i++)
  {
    buf[i] = 0xFFFFFF;
  }
    //buf[i] = 0xFFFF;//make_color(18, 18, 18);

  //if(v_mode->width == 1200)
  //  __asm__("jmp 0xFFFF");
  while(1);
}
