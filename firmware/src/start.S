.section .text.init
.global _start
_start:
    li sp, 0x0700      # was 0x07F8 — moved away from MMIO at 0x07F8/0x07FC

    jal ra, main

    li t0, 0x07FC
    li t1, 1
    sw t1, 0(t0)

halt:
    j halt