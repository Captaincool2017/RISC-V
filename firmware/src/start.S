.section .text.init
.global _start
_start:
    li sp, 0x05FC

    jal ra, main

    li t0, 0x07FC
    li t1, 1
    sw t1, 0(t0)

halt:
    j halt