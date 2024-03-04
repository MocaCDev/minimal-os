#ifndef UTIL_HPP
#define UTIL_HPP
#include "types.hpp"

namespace util 
{
    extern "C" u32 __attribute__((cdecl)) strlen(u8 *);

    template<typename S1, typename S2>
    static bool strcmp(S1 str1, S2 str2)
    {
        if(strlen(str1) != strlen((u8 *)str2.get()))
            return false;
        
        u32 i = 0;
        while(str1[i])
        {
          if(str1[i] != *str2) return false;
          i++;
          ++str2;

          if(str1[i + 1] == '\0')
            break;
        }
    
        return true;
    }

    
    template<typename FromDT, typename ToDT>
    ToDT cast(FromDT variable)
    {
        return (ToDT)variable;
    }
}

#endif
