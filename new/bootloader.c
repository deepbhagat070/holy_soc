#include <stdint.h>

#define UART_TX_REG    ((volatile uint32_t*) 0x90000000)
#define UART_RX_STATUS ((volatile uint32_t*) 0x90000004)
#define UART_RX_DATA   ((volatile uint32_t*) 0x90000008)

void uart_putc(char c) {
    *UART_TX_REG = c;
}

void print_str(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

int main(void) {
    uint32_t *ram_ptr = (uint32_t *)0x40000000;

    print_str("Booting...\n");

    while (1) {
        uint32_t word = 0;
        
        // 3. Byte Reassembly (4 bytes per 32-bit word)
        for (int byte_idx = 0; byte_idx < 4; byte_idx++) {
            // 2. UART Polling (Wait until RX FIFO is not empty)
            // Bit 1 is rx_not_empty
            while ((*UART_RX_STATUS & 0x02) == 0) {
                // Wait for data
            }
            // Read the byte and shift it into the Little-Endian word
            uint32_t b = *UART_RX_DATA;
            word |= (b << (byte_idx * 8));
        }

        // Termination condition: if we receive 0xFFFFFFFF, stop loading
        if (word == 0xFFFFFFFF) {
            break;
        }

        // 4. Writing to Main RAM
        *ram_ptr = word;
        ram_ptr++;
    }

    print_str("Loaded!\n");

    // Solve the Cache Coherency Trap!
    // Flush D-Cache and Invalidate I-Cache
    __asm__ volatile ("fence.i");

    // 5. Execution Handoff
    void (*main_program)(void) = (void (*)(void))0x40000000;
    main_program();

    return 0;
}
