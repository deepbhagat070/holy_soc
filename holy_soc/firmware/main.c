#include <stdint.h>



#define UART_TX_REG ((volatile uint32_t*) 0x90000000)
#define AES_KEY    ((volatile uint32_t*) 0xA0000000)
#define AES_TEXT   ((volatile uint32_t*) 0xA0000010)
#define AES_START  ((volatile uint32_t*) 0xA0000020)
#define AES_DONE   ((volatile uint32_t*) 0xA0000024)
#define AES_RESULT ((volatile uint32_t*) 0xA0000028)
#define TIMEOUT_CYCLES 300000

#define TOTAL_TESTS 55   

void uart_putc(char c) { *UART_TX_REG = (uint32_t)c; }

void print_hex(uint32_t val) {
    uart_putc('0'); uart_putc('x');
    for (int i = 28; i >= 0; i -= 4) {
        uint32_t nib = (val >> i) & 0xF;
        uart_putc(nib < 10 ? ('0' + nib) : ('A' + (nib - 10)));
    }
    uart_putc('\n');
}

volatile uint32_t results[64];
volatile uint32_t signature;
int idx = 0;

void check(char c1, char c2, char c3, char c4, char c5, int pass) {
    uart_putc(c1); uart_putc(c2); uart_putc(c3); uart_putc(c4); uart_putc(c5);
    uart_putc(':'); uart_putc(' ');
    if (pass) { uart_putc('P');uart_putc('A');uart_putc('S');uart_putc('S'); }
    else      { uart_putc('F');uart_putc('A');uart_putc('I');uart_putc('L'); }
    uart_putc('\n');

    results[idx] = pass ? 1 : 0;

    signature ^= pass ? 0xA5A5A5A5u : 0x5A5A5A5Au;
    signature = (signature << 3) | (signature >> 29);
    signature = signature + (uint32_t)idx;

    idx++;
}


volatile int ra, rb;
void test_rtype(void) {
    int rd;
    rd = ra + rb;  check('A','D','D',' ',' ', rd == 13);
    rd = ra - rb;  check('S','U','B',' ',' ', rd == 7);
    asm volatile("sll %0,%1,%2" : "=r"(rd) : "r"(1), "r"(4));
    check('S','L','L',' ',' ', rd == 16);
    asm volatile("slt %0,%1,%2" : "=r"(rd) : "r"(-5), "r"(3));
    check('S','L','T',' ',' ', rd == 1);
    unsigned ua = 1, ub = 0xFFFFFFFFu;
    asm volatile("sltu %0,%1,%2" : "=r"(rd) : "r"(ua), "r"(ub));
    check('S','L','T','U',' ', rd == 1);
    rd = ra ^ rb;  check('X','O','R',' ',' ', rd == 9);
    unsigned ushr = 0xF0u;
    asm volatile("srl %0,%1,%2" : "=r"(rd) : "r"(ushr), "r"(4));
    check('S','R','L',' ',' ', rd == 0x0F);
    int sar = -16;
    asm volatile("sra %0,%1,%2" : "=r"(rd) : "r"(sar), "r"(2));
    check('S','R','A',' ',' ', rd == -4);
    rd = ra | rb;  check('O','R',' ',' ',' ', rd == 11);
    rd = ra & rb;  check('A','N','D',' ',' ', rd == 2);
}

void test_itype(void) {
    int rd;
    rd = ra + 5;  check('A','D','D','I',' ', rd == 15);
    volatile int neg10 = -10;
    asm volatile("slti %0,%1,5" : "=r"(rd) : "r"(neg10));
    check('S','L','T','I',' ', rd == 1);
    volatile unsigned u3 = 3;
    asm volatile("sltiu %0,%1,5" : "=r"(rd) : "r"(u3));
    check('S','L','T','I','U', rd == 1);
    rd = ra ^ 6;  check('X','O','R','I',' ', rd == 12);
    rd = ra | 5;  check('O','R','I',' ',' ', rd == 15);
    rd = ra & 6;  check('A','N','D','I',' ', rd == 2);
    asm volatile("slli %0,%1,3" : "=r"(rd) : "r"(1));
    check('S','L','L','I',' ', rd == 8);
    volatile unsigned u80 = 0x80u;
    asm volatile("srli %0,%1,4" : "=r"(rd) : "r"(u80));
    check('S','R','L','I',' ', rd == 0x08);
    volatile int neg32 = -32;
    asm volatile("srai %0,%1,2" : "=r"(rd) : "r"(neg32));
    check('S','R','A','I',' ', rd == -8);
}


volatile uint32_t ls_mem[2];

void test_memory_access(void) {
    int res;

    ls_mem[0] = 0xDEADBEEF;
    check('S','W',' ',' ',' ', ls_mem[0] == 0xDEADBEEF);
    uint32_t v = ls_mem[0];
    check('L','W',' ',' ',' ', v == 0xDEADBEEF);

    ls_mem[0] = 0x11223344;
    asm volatile("sb %1, 0(%0)" : : "r"(ls_mem), "r"(0xAA));
    check('S','B',' ','0',' ', ls_mem[0] == 0x112233AA);

    ls_mem[0] = 0x11223344;
    asm volatile("sb %1, 1(%0)" : : "r"(ls_mem), "r"(0xBB));
    check('S','B',' ','1',' ', ls_mem[0] == 0x1122BB44);

    ls_mem[0] = 0x11223344;
    asm volatile("sb %1, 2(%0)" : : "r"(ls_mem), "r"(0xCC));
    check('S','B',' ','2',' ', ls_mem[0] == 0x11CC3344);

    ls_mem[0] = 0x11223344;
    asm volatile("sb %1, 3(%0)" : : "r"(ls_mem), "r"(0xDD));
    check('S','B',' ','3',' ', ls_mem[0] == 0xDD223344);

    ls_mem[0] = 0x11223344;
    asm volatile("sh %1, 0(%0)" : : "r"(ls_mem), "r"(0xAABB));
    check('S','H',' ','0',' ', ls_mem[0] == 0x1122AABB);

    ls_mem[0] = 0x11223344;
    asm volatile("sh %1, 2(%0)" : : "r"(ls_mem), "r"(0xCCDD));
    check('S','H',' ','2',' ', ls_mem[0] == 0xCCDD3344);

    ls_mem[1] = 0x89ABCDEF;

    asm volatile("lb %0, 0(%1)" : "=r"(res) : "r"(&ls_mem[1]));
    check('L','B',' ','0',' ', res == (int)0xFFFFFFEF);

    asm volatile("lbu %0, 0(%1)" : "=r"(res) : "r"(&ls_mem[1]));
    check('L','B','U','0',' ', res == 0x000000EF);

    asm volatile("lb %0, 3(%1)" : "=r"(res) : "r"(&ls_mem[1]));
    check('L','B',' ','3',' ', res == (int)0xFFFFFF89);

    asm volatile("lh %0, 0(%1)" : "=r"(res) : "r"(&ls_mem[1]));
    check('L','H',' ','0',' ', res == (int)0xFFFFCDEF);

    asm volatile("lhu %0, 0(%1)" : "=r"(res) : "r"(&ls_mem[1]));
    check('L','H','U','0',' ', res == 0x0000CDEF);
}

volatile int va, vb, vc, vd;
volatile unsigned vu1, vu2;

void test_branches(void) {
    int taken;
    taken = 0; if (va == vb) taken = 1;   check('B','E','Q',' ',' ', taken==1);
    taken = 0; if (vc != vd) taken = 1;   check('B','N','E',' ',' ', taken==1);
    taken = 0; if (vd < vc)  taken = 1;   check('B','L','T',' ',' ', taken==1);
    taken = 0; if (vc >= vd) taken = 1;   check('B','G','E',' ',' ', taken==1);
    taken = 0; if (vu2 < vu1) taken = 1;  check('B','L','T','U',' ', taken==1);
    taken = 0; if (vu1 >= vu2) taken = 1; check('B','G','E','U',' ', taken==1);
}

void test_upper_imm(void) {
    int rd;
    asm volatile("lui %0, 0x12345" : "=r"(rd));
    check('L','U','I',' ',' ', (rd & 0xFFFFF000) == 0x12345000);
}

volatile uint32_t hazard_mem;
void test_hazards(void) {
    volatile int h1 = -8;
    int h2 = h1 ^ 15;
    check('E','X','H','A','Z', h2 == -9);

    volatile int h3 = 10;
    volatile int noise = h3 + 1;
    results[63] = noise;
    int h4 = h3 + 5;
    check('M','E','H','A','Z', h4 == 15);

    volatile int h5 = 5;
    h5 = 10;
    int h6 = h5 + 1;
    check('W','A','W','H','Z', h6 == 11);

    hazard_mem = 77;
    uint32_t loaded = hazard_mem;
    uint32_t h7 = loaded + 1;
    check('L','D','U','S','E', h7 == 78);

    volatile int h8 = 5;
    int h9 = 5;
    int h10 = 0;
    if (h8 == h9) { h10 = 1; }
    check('B','R','H','A','Z', h10 == 1);
}

void test_gauntlet(void) {
    int result;
    uint32_t poison;
    asm volatile(
        "addi t0, x0, 5\n\t"
        "addi t1, t0, 3\n\t"
        "add  t2, t1, t0\n\t"
        "sub  t3, t2, t1\n\t"
        "sll  t4, t3, 1\n\t"
        "xor  t5, t4, t3\n\t"
        "and  t6, t5, t4\n\t"
        "or   t0, t6, t5\n\t"
        "slt  t1, t0, t6\n\t"
        "addi t2, x0, 0\n\t"
        "beq  t1, x0, 1f\n\t"
        "addi t2, x0, 999\n\t"
        "1: addi %0, t6, 0\n\t"
        "addi %1, t2, 0\n\t"
        : "=r"(result), "=r"(poison)
        :
        : "t0","t1","t2","t3","t4","t5","t6"
    );
    check('H','Z','C','H','N', result == 10);
    check('H','Z','P','S','N', poison == 0);
}

volatile uint32_t chain_mem[2];
void test_load_chain(void) {
    int result;
    asm volatile(
        "addi t0, x0, 42\n\t"
        "sw   t0, 0(%1)\n\t"
        "lw   t1, 0(%1)\n\t"
        "addi t2, t1, 8\n\t"
        "sw   t2, 4(%1)\n\t"
        "lw   t3, 4(%1)\n\t"
        "add  %0, t3, x0\n\t"
        : "=r"(result)
        : "r"(chain_mem)
        : "t0","t1","t2","t3","memory"
    );
    check('L','D','C','H','N', result == 50);
}

void test_aes(void) {
    volatile uint32_t key0 = 0x2b7e1516, key1 = 0x28aed2a6, key2 = 0xabf71588, key3 = 0x09cf4f3c;
    volatile uint32_t pt0 = 0x3243f6a8, pt1 = 0x885a308d, pt2 = 0x313198a2, pt3 = 0xe0370734;
    volatile uint32_t exp0 = 0x3925841d, exp1 = 0x02dc09fb, exp2 = 0xdc118597, exp3 = 0x196a0b32;

    AES_KEY[0]=key0; AES_KEY[1]=key1; AES_KEY[2]=key2; AES_KEY[3]=key3;
    AES_TEXT[0]=pt0; AES_TEXT[1]=pt1; AES_TEXT[2]=pt2; AES_TEXT[3]=pt3;
    *AES_START = 1;

    uint32_t timeout = 0, hung = 0;
    while ((*AES_DONE & 0x2) == 0) {
        timeout++;
        if (timeout > TIMEOUT_CYCLES) { hung = 1; break; }
    }

    if (hung) {
        check('A','E','S',' ',' ', 0);
    } else {
        uint32_t c0=AES_RESULT[0], c1=AES_RESULT[1], c2=AES_RESULT[2], c3=AES_RESULT[3];
        int pass = (c0==exp0) && (c1==exp1) && (c2==exp2) && (c3==exp3);
        check('A','E','S',' ',' ', pass);
    }
}

void test_traps(void) {
    uint32_t r0, r1, r2, r3, r4, r5;

    asm volatile(
        "la   t0, 2f\n\t"
        "csrw mtvec, t0\n\t"

        "li   t1, 0\n\t"
        "ecall\n\t"
        "addi %0, t1, 0\n\t"
        "csrr %1, mcause\n\t"

        "j    3f\n\t"

        "2:\n\t"
        "addi t1, t1, 1\n\t"
        "csrr t4, mepc\n\t"
        "addi t4, t4, 4\n\t"
        "csrw mepc, t4\n\t"
        "mret\n\t"
        "3:\n\t"

        "li   t5, 305\n\t"
        "csrw mscratch, t5\n\t"
        "csrr %2, mscratch\n\t"

        "csrrs x0, mscratch, x0\n\t"
        "csrr %3, mscratch\n\t"

        "ebreak\n\t"
        "csrr %4, mcause\n\t"
        "addi %5, t1, 0\n\t"

        : "=r"(r0), "=r"(r1), "=r"(r2), "=r"(r3), "=r"(r4), "=r"(r5)
        :
        : "t0","t1","t4","t5","memory"
    );

    check('E','C','A','L','1', r0 == 1);   
    check('E','C','A','L','2', r1 == 11);    
    check('C','S','R','W','1', r2 == 305);  
    check('C','S','R','W','2', r3 == 305);   
    check('E','B','R','K','1', r4 == 3);     
    check('E','B','R','K','2', r5 == 2);   

    int traps_pass = (r0==1) && (r1==11) && (r2==305) && (r3==305) && (r4==3) && (r5==2);
    results[61] = traps_pass ? 1 : 0;
}

void init_globals(void) {
    ra = 10; rb = 3;
    va = 5; vb = 5; vc = 10; vd = 3;
    vu1 = 0xFFFFFFFFu; vu2 = 1;
    signature = 0x12345678;
}

uint32_t get_golden_signature(void) {
    uint32_t sig = 0x12345678;
    for (int i = 0; i < TOTAL_TESTS; i++) {
        sig ^= 0xA5A5A5A5u;
        sig = (sig << 3) | (sig >> 29);
        sig += i;
    }
    return sig;
}

int main(void) {
    init_globals();

    uart_putc('=');uart_putc('=');uart_putc('=');uart_putc(' ');
    uart_putc('T');uart_putc('O');uart_putc('R');uart_putc('T');uart_putc('U');
    uart_putc('R');uart_putc('E');uart_putc(' ');uart_putc('T');uart_putc('E');
    uart_putc('S');uart_putc('T');uart_putc('\n');

    test_rtype();           
    test_itype();          
    test_memory_access();   
    test_branches();        
    test_upper_imm();       
    test_hazards();         
    test_gauntlet();       
    test_load_chain();     
    test_aes();             
    test_traps();         


    results[60] = signature;
    uint32_t golden = get_golden_signature();
    results[62] = golden;     

    uart_putc('S');uart_putc('I');uart_putc('G');uart_putc(':');uart_putc(' ');
    print_hex(signature);

    int sig_ok = (signature == golden);
    uart_putc('S');uart_putc('I');uart_putc('G');uart_putc('C');uart_putc('K');
    uart_putc(':');uart_putc(' ');
    if (sig_ok) { uart_putc('P');uart_putc('A');uart_putc('S');uart_putc('S'); }
    else        { uart_putc('F');uart_putc('A');uart_putc('I');uart_putc('L'); }
    uart_putc('\n');

    uart_putc('T');uart_putc('R');uart_putc('P');uart_putc(':');uart_putc(' ');
    if (results[61]) { uart_putc('P');uart_putc('A');uart_putc('S');uart_putc('S'); }
    else              { uart_putc('F');uart_putc('A');uart_putc('I');uart_putc('L'); }
    uart_putc('\n');

    while (1) {  }
    return 0;
}