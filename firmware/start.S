.section .text
.global _start

_start:
    /* 1. Load the Stack Pointer */
    lui sp, 0x20001
    
    /* 2. PIPELINE FLUSH: Wait for the Register File to update */
    nop
    nop
    nop
    nop
    nop
    
    /* 3. Now it is safe to read 'sp' */
    addi sp, sp, -4
    
    /* 4. Flush again before jumping */
    nop
    nop
    nop
    
    jal main

end_loop:
    j end_loop