#ifndef TEST_API_H
#define TEST_API_H

// Changed to 0x07FC (2044) so it fits perfectly in a standard 12-bit immediate.
// This prevents GCC from generating LUI instructions!
#define TB_CTRL_ADDR   0x07FC  
#define TB_RESULT_ADDR 0x07F8  

volatile int * const tb_ctrl   = (int *)TB_CTRL_ADDR;
volatile int * const tb_result = (int *)TB_RESULT_ADDR;

// Call this if your test passes
static inline void test_pass() {
    *tb_ctrl = 1; 
    while(1); // Halt
}

// Call this if your test fails
static inline void test_fail() {
    *tb_ctrl = 2; 
    while(1); // Halt
}

// Call this to output a specific mathematical result
static inline void test_done_with_result(int result) {
    *tb_result = result;
    *tb_ctrl = 3; 
    while(1); // Halt
}

#endif