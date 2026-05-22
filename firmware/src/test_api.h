#ifndef TEST_API_H
#define TEST_API_H

#define TB_CTRL_ADDR   0x07FC
#define TB_RESULT_ADDR 0x07F8
// Stack must stay below 0x07F0 — collision = silent wrong result

static inline void test_pass() {
    *((volatile int *)TB_CTRL_ADDR) = 1;
    while(1);
}

static inline void test_fail() {
    *((volatile int *)TB_CTRL_ADDR) = 2;
    while(1);
}

static inline void test_done_with_result(int result) {
    *((volatile int *)TB_RESULT_ADDR) = result;
    *((volatile int *)TB_CTRL_ADDR)   = 3;
    while(1);
}

#endif