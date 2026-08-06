.section .text
.global _start
_start:
    /* 1. Load the Stack Pointer.
       UPDATED: was 0x20001, pointing at the old (now invalid under
       the new memory map) RAM address. New RAM window is
       0x0000C000 - 0x0000FFFF; set sp to the top of the WHOLE 64KB
       array (0x00010000), just past RAM's end, growing downward --
       matches the same "sp at top, grows down" pattern as before,
       just at the new address. */
    lui sp, 0x10
    
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
