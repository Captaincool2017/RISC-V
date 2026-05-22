.global _start
_start:
    # Initialize stack pointer safely inside the 12-bit immediate range
    li sp, 0x07F8
    
    # Call main in C
    jal ra, main
    
    # If main returns normally, tell the testbench it PASSED (Code 1 -> 0x07FC)
    li t0, 0x07FC
    li t1, 1
    sw t1, 0(t0)

halt:
    j halt