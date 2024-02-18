#pragma once
//#ifndef COMMON_H
//#define COMMON_H  

#ifdef __cplusplus
extern "C"
{
#endif



#ifdef __cplusplus
}
#endif

u8 inp_byte(u16 port)
{
  u8 value;

  __asm__ volatile ("inb %0, %1" : "=a"(value) : "Nd"(port));

  return value;
}

//#endif
