#ifndef TYPES_H
#define TYPES_H

#ifdef __cplusplus
extern "C"
{
#endif

typedef char                i8;
typedef unsigned char       u8;
typedef signed char         s8;
typedef char *              p_i8;
typedef unsigned char *     p_u8;
typedef signed char *       p_s8;

typedef short               i16;
typedef unsigned short      u16;
typedef signed short        s16;
typedef short *             p_i16;
typedef unsigned short *    p_u16;
typedef signed short *      p_s16;

typedef int                 i32;
typedef unsigned int        u32;
typedef signed int          s32;
typedef int *               p_i32;
typedef unsigned int *      p_u32;
typedef signed int *        p_s32;

typedef long                li32;
typedef unsigned long       lu32;
typedef signed long         ls32;
typedef long *              p_li32;
typedef unsigned long *     p_lu32;
typedef signed long *       p_ls32;

typedef long long           lli32;
typedef unsigned long long  llu32;
typedef signed long long    lls32;
typedef long long *         p_lli32;
typedef unsigned long long* p_llu32;
typedef signed long long *  p_lls32;

#ifdef __cplusplus
}
#endif

#define c_char_id     (u32)0xFABE

class c_char 
{
private:
    i8    *data;
    u32   index;
    u32   data_length = 0x1;

public:
    /*c_char(const i8 *string)
    {
        data = (i8 *)0x100;
        u32 i = 0;
        while(true)
        {
            if(string[i] == 0x0) break;

            data[i] = string[i];
            i++;
        }
    }*/

    c_char(u32 dl)
        : data_length(dl)
    {
        data = (i8 *)0x100;

        for(int i = 0; i < data_length; i++)
            data[i] = 0x0;
    }

    explicit c_char() = default;

    u32 type_id() const { return c_char_id; }
    i8 *get() const { return data; }
    u32 get_length() { return data_length; }

    i8 operator*() { return data[index]; }
    void operator++() { index++; }
    c_char& operator=(const i8 *string)
    {
        if(this->data_length == 0)
        {
            u32 index = 0;
            while(true)
            {
                if(string[index] == 0x0) break;

                data[index] = string[index];
                index++;
            }

            data[index] = 0x0;

            return *this;
        }

        for(int i = 0; i < data_length; i++)
            data[i] = string[i];
        
        return *this;
    }

    ~c_char() = default;
};

template<typename T>
concept is_cchar = requires(T t)
{
    t.type_id() == c_char_id;
};

using cchar = struct c_char;

/* Probably useless, but oh well. */ 
#ifdef NULL
#undef NULL 
#endif

#define NULL  0x0
#define true  0x1
#define false 0x0

#endif
