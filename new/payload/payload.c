#include <stdint.h>

#define UART_TX_REG ((volatile uint32_t*) 0x90000000)

void uart_putc(char c) {
    // Wait until TX is not busy (Bit 0 of TX status, but we don't have it defined here,
    // and UART is fast enough in sim to just write directly if we assume it doesn't overflow)
    // For safety, just write to the TX register.
    *UART_TX_REG = c;
}

void print_str(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

void print_hex(uint32_t val) {
    print_str("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uint32_t nibble = (val >> i) & 0xF;
        if (nibble < 10) {
            uart_putc('0' + nibble);
        } else {
            uart_putc('A' + (nibble - 10));
        }
    }
    uart_putc('\n');
}

int main(void) {
    print_str("Payload Started!\n");
    
    // Perform a math calculation: 20th Fibonacci number
    uint32_t a = 0;
    uint32_t b = 1;
    for (int i = 0; i < 20; i++) {
        uint32_t next = a + b;
        a = b;
        b = next;
    }
    // The 20th Fibonacci number is 10946 (0x2AC2)
    
    print_str("Fibonacci(20) = ");
    print_hex(b);
    
    print_str("Math Test Complete.\n");
    
    while(1) {} // Halt
    return 0;
}
