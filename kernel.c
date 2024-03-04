/*
Vesa_Info_Block *v_mode = (Vesa_Info_Block *)0x5000;

#define make_color(r,g,b) r*65536 + g*256 + b
#define buffer v_mode->framebuffer
*/

#include "include/util.hpp"
#include "include/vesa.hpp"
#include "include/types.hpp"

static u16 *buf = (u16 *)0xB8000;

void __attribute__((section("__start"))) main(void)
{
    //print((u8 *)"hi");
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
