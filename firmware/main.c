#define STATUS_ADDR ((volatile unsigned int*) 0x20000020)

int main(void) {
    unsigned int flush_flag;

    asm volatile(
        ".option push\n\t"
        ".option norvc\n\t"
        
        "la t0, trap_handler\n\t"
        "csrw mtvec, t0\n\t"
        "li %0, 0\n\t"

        "ebreak\n\t"

        "addi %0, %0, 1\n\t"
        "addi %0, %0, 1\n\t"
        "addi %0, %0, 1\n\t"

        "j end_test\n\t"

        "trap_handler:\n\t"
        "csrr t2, mepc\n\t"
        "addi t2, t2, 16\n\t"
        "csrw mepc, t2\n\t"
        "mret\n\t"

        "end_test:\n\t"
        ".option pop\n\t"
        : "=r"(flush_flag)
        :
        : "t0", "t2"
    );

    *STATUS_ADDR = (flush_flag == 0) ? 0x11111111 : 0x99999999;

    while (1) { /* Halt */ }
}