ENTRY(_start)

MEMORY
{
    MEM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    . = 0x00000000;

    .text : {
        *(.text.init)
        *(.text*)
    } > MEM

    .rodata : {
        *(.rodata*)
    } > MEM

    .data : {
        *(.data*)
    } > MEM

    .bss : {
        *(.bss*)
        *(COMMON)
    } > MEM

    /DISCARD/ : {
        *(.riscv.attributes)
        *(.comment)
        *(.eh_frame)
    }
}