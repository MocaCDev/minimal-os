#ifndef VESA_HPP
#define VESA_HPP
#include "util.hpp"

/* Address where we want `struct vbe_info_block` to be stored. */
#define VBE_INFO_BLOCK_ADDR   (u16)0x800

namespace vesa 
{
    struct vesa_setup
    {
        u16     vesa_width;
        u16     vesa_height;
        u8      vesa_bpp;
    };

    struct vbe_info_block
    {
        u8      signature[4];   /* "VESA" */ 
        u16     version;        /* 0x300 = VBE 3.0 */ 
        u16     oem_str_ptr[2];
        u8      cap[4];
        u32     vid_mode_ptr;   /* can also be `u16 vid_mode_ptr[2]` */
        u16     total_memory;
        u8      reserved[492];
    } __attribute__((packed));

    struct VesaInfoBlock
    {
      u16		attributes;
	    u8		window_a;
	    u8		window_b;
	    u16		gran;
	    u16		window_size;
	    u16		seg_a;
	    u16		seg_b;
	    u32		win_func_ptr;
	    u16		pitch;
	    u16		width;
	    u16		height;
	    u8		w_char;
	    u8		y_char;
	    u8		planes;
	    u8		bpp;
	    u8		banks;
        u8		memory_model;
	    u8		bank_size;
	    u8		image_pages;
	    u8		reserved1;
	    u8		red_mask;
	    u8		red_pos;
	    u8		green_mask;
	    u8		green_pos;
	    u8		blue_mask;
	    u8		blue_pos;
	    u8		reserved_mask;
	    u8		reserved_pos;
	    u8		direct_color_attributes;
	    u32		framebuffer;
	    u32		off_screen_mem_off;
	    u16		off_screen_mem_size;
	    u8		reserved2[206];
    } __attribute__((packed)) Vesa_Info_Block;

    /* Attempt to obtain video mode information based on the structure `vesa_setup`. */
    extern "C" u16 __attribute__((cdecl)) check_for_mode(struct vesa_setup, u16);

    /* Print string length/string data using BIOS. */
    extern "C" void __attribute__((cdecl)) bit16_print_string_info(u16, u8 *);

    /* Expects a 16-bit value that refers to the vesa video mode # */
    extern "C" u16 __attribute__((cdecl)) set_vesa_mode(u16);

    /* TODO: Remove. Vesa will be used, thus leading to the below variable to 
     * be useless.
     * */
    static u16 *t = (u16 *)0xB8000;
    static u16 y = 0;
    static u16 x = 0;

    template<typename T>
        requires is_cchar<T>
    void print(T value)
    {
        u32 i = 0;

        /* Obtain string data. */ 
        i8 *str = value.get();

        /* Print it out. */ 
        while(str[i])
        {
            if(str[i] == '\n')
            {
                x = 0;
                y++;
                i++;
                continue;
            }

            t[x + (y * 80)] = (0x0F << 0x08) | (0xFF & str[i]);
    
            x++;
            i++; 

            if(str[i + 1] == '\0')
                break;
        }
    }

    class VSetup
    {
    protected:
        /* Vesa Setup (vsetup) */ 
        struct vesa_setup vsetup;

        /* VBE Info (vbei) */ 
        struct vbe_info_block *vbei;

        /* Display mode # */ 
        u16 display_mode;
    
    private:
        /* `struct vbe_info_block` explicit information (what we expect) */
        cchar vesa_sig = "VESA";
    
    public:
        explicit VSetup(u16 width, u16 height, u8 bpp)
            : display_mode(0), vbei(NULL)
        {
            /* Set the vesa setup information. */
            vsetup.vesa_width = width;
            vsetup.vesa_height = height;
            vsetup.vesa_bpp = bpp;
        }

        void attempt_obtain_mode()
        {
            display_mode = check_for_mode(vsetup, VBE_INFO_BLOCK_ADDR);
            
            vbei = (struct vbe_info_block *)VBE_INFO_BLOCK_ADDR;
            cchar is_good = "good!";
            cchar is_bad = "bad!";
            cchar val = "dude";//(const i8 *)vbei->signature;

            if(util::strcmp<u8 *, cchar>(vbei->signature, vesa_sig) == true)
                print(is_good);
            else
             print(is_bad);
        }

        ~VSetup() = default;
    };
}

#endif
