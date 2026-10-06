.section .text
.global _start
_start:
    /* Set stack pointer to end of Main RAM (0x40004000) */
    lui sp, 0x40004
    
    nop
    nop
    nop
    nop
    nop
    
    addi sp, sp, -4
    
    nop
    nop
    nop
    
    jal main
end_loop:
    j end_loop
