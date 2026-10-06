OUTPUT_ARCH( "riscv" )
ENTRY( _start )
MEMORY
{
  rom (rx)  : ORIGIN = 0x00000000, LENGTH = 4096   /* 4KB Boot ROM */
  ram (rwx) : ORIGIN = 0x40000000, LENGTH = 16384  /* 16KB Main RAM */
}
SECTIONS
{
  .text : {
    *(.text)
  } > rom
  .data : {
    *(.data)
  } > ram
  .bss : {
    *(.bss)
  } > ram
}
