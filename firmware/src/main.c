#include "test_api.h"

// Manual div/mod using hardware DIV instruction via inline asm
static inline int hw_div(int a, int b)
{
    int q;
    __asm__ volatile("div %0, %1, %2" : "=r"(q) : "r"(a), "r"(b));
    return q;
}
static inline int hw_rem(int a, int b)
{
    int r;
    __asm__ volatile("rem %0, %1, %2" : "=r"(r) : "r"(a), "r"(b));
    return r;
}

// ─── Bug 4: stack depth test ───────────────────────────────
int recurse(int depth)
{
    if (depth <= 0)
        return 1;
    return recurse(depth - 1) + depth;
}

// ─── Bug 1: division result ────────────────────────────────
int test_div()
{
    int q = hw_div(100, 7); // expect 14
    int r = hw_rem(100, 7); // expect 2
    if (q != 14)
        return 0;
    if (r != 2)
        return 0;
    return 1;
}

// ─── Bug 2: branch after div stall ────────────────────────
int test_branch_after_div()
{
    int q = hw_div(50, 5); // expect 10
    if (q == 10)
        return 1;
    return 0;
}

// ─── Bug 3: JALR after load ───────────────────────────────
int add(int a, int b) { return a + b; }

int test_jalr_load()
{
    volatile int (*fp)(int, int) = add;
    int result = fp(3, 4); // expect 7
    return (result == 7) ? 1 : 0;
}

// ──────────────────────────────────────────────────────────
int main()
{
    int dummy[4] = {1, 2, 3, 4};
    if (recurse(3) != 7)
        test_done_with_result(40);
    if (!test_div())
        test_done_with_result(10);
    if (!test_branch_after_div())
        test_done_with_result(20);
    if (!test_jalr_load())
        test_done_with_result(30);
    test_done_with_result(99);
}