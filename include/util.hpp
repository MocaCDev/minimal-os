#ifndef UTIL_HPP
#define UTIL_HPP
#include <types.hpp>
#include <util.hpp>

namespace util 
{
    extern "C" u32 __attribute__((cdecl)) strlen(u8 *);

    template<typename S1, typename S2>
    static bool strcmp(S1 str1, S2 str2)
    {
        if(strlen(cast<S1, u8 *>(str1)) != strlen(cast<S2, u8*>(str2)))
            return false;
    
        return true;
    }

    
    template<typename FromDT, typename ToDT>
    ToDT cast(FromDT variable)
    {
        return (ToDT)variable;
    }
}

#endif
