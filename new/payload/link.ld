OUTPUT_ARCH( "riscv" )
ENTRY( _start )
MEMORY
{
  ram (rwx) : ORIGIN = 0x40000000, LENGTH = 16384
}

SECTIONS
{
  .text :
  {
    *(.text .text.*)
  } > ram

  .rodata :
  {
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > ram

  .data :
  {
    *(.data .data.*)
    *(.sdata .sdata.*)
  } > ram

  .bss :
  {
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
  } > ram
}
