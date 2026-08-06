OUTPUT_ARCH( "riscv" )
ENTRY( _start )
MEMORY
{
  /* UPDATED: both regions now live within main_memory's single 64KB
     array (16384 words = 65536 bytes = 0x10000), since Boot ROM and
     Main RAM temporarily share one physical backing store (see
     main_memory.v comments). Both start with addr[31]=0, so both are
     cacheable and both route to the same slave for now.

     48KB for code (plenty of headroom -- your current program is
     ~6.2KB), 16KB for data/bss (generous given your .bss has
     historically been a few hundred bytes). */
  rom (rx)  : ORIGIN = 0x00000000, LENGTH = 49152   /* 0xC000 = 48K */
  ram (rwx) : ORIGIN = 0x0000C000, LENGTH = 16384    /* 0x4000 = 16K */
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
