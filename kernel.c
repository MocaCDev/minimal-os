/*#include "include/io.hpp"
typedef unsigned char		uint8;
typedef char			int8;
typedef unsigned short		uint16;
typedef short			int16;
typedef unsigned int		uint32;
typedef int			int32;
typedef unsigned long long	uint64, size_t;
typedef long long		int64;

#include <types.hpp>
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
*/
//extern "C" void __attribute__((cdecl)) x86_Disk_Reset();
//extern "C" void __attribute__((cdecl)) t();

//void testing()
//{
//  x86_Disk_Reset();
//}

#include <util.hpp>
#include <vesa.hpp>

static u16 *buf = (u16 *)0xB8000;
static u16 y = 0;
static u16 x = 0;

void print(u8 *value)
{
    u32 i = 0;
    while(value[i])
    {
        buf[x  + (y * 80)] = (0x0F << 8) | (0xFF & value[i]);
        i++;
        x++;
    }
}

void __attribute__((section("__start"))) main(void)
{
    print((u8 *)"hi");
    //u8 *d = (u8 *)0x100;
    //const char b[5] = "WOWW";
    //for(int i = 0; i < 5; i++)
    //    d[i] = b[i];
    //tryy2(0x5, d);

    //util::t();
  
    //unsigned short *b = (unsigned short *)(0x7C00 + 0x12F);

    //if(b[0] == 0x640
    //  d[0] = 'N';
  
    vesa::VSetup vstp(0x640, 0x4B0, 0x20);

    vstp.attempt_obtain_mode();

    while(1);
}
