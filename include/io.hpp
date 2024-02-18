#ifndef C 
#define C 
#include "types.hpp"

static u8 inp_byte(u16 port_number)
{
  u8 value;

  __asm__("inb %0, %1" : "=a"(value) : "Nd"(port_number));

  return value;
}

static void outp_byte(u16 port_number, u8 data)
{
  __asm__("outb %0, %1" : : "a"(data), "Nd"(port_number));
}

#endif
