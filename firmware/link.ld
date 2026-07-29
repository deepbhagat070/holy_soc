OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  /* Instruction ROM starts at 0x0, max size 4KB */
  rom (rx)  : ORIGIN = 0x00000000, LENGTH = 8192
  
  /* Data RAM starts at 0x20000000, max size 4KB */
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 8192
}

SECTIONS
{
  /* Put the bootloader and code in the ROM */
  .text : {
    *(.text)
  } > rom

  /* Put initialized data (like global variables) in RAM */
  .data : {
    *(.data)
  } > ram

  /* Put uninitialized data (like arrays) in RAM */
  .bss : {
    *(.bss)
  } > ram
}