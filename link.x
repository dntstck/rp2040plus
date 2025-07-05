ENTRY(Reset)

MEMORY
{
  FLASH : ORIGIN = 0x10000000, LENGTH = 16M
  RAM   : ORIGIN = 0x20000000, LENGTH = 256K
}

SECTIONS
{
  .vector_table ORIGIN(FLASH) :
  {
    KEEP(*(.vector_table))
  } > FLASH

  .text :
  {
    *(.text .text.*)
    *(.rodata .rodata.*)
  } > FLASH

  .data : AT (ADDR(.text) + SIZEOF(.text))
  {
    __sdata = .;
    *(.data .data.*)
    __edata = .;
  } > RAM

  .bss :
  {
    __sbss = .;
    *(.bss .bss.*)
    *(COMMON)
    __ebss = .;
  } > RAM

  .stack (COPY):
  {
    . = ALIGN(8);
    . += 0x1000;
    PROVIDE(_stack_start = .);
  } > RAM

  __sidata = LOADADDR(.data);
}

PROVIDE(__pre_init = 0);
