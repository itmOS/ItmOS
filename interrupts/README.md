ItmOS::interrupts
===========

Module for interrupt support.

<i>All macros are in interrupts/interrupts.inc</i>

Tutorial for adding interrupt handler:
--------
1. Write handler body(Ex. <i>timer_int</i>).
  You _DON'T_ need to save registers or send EOI(End of Interrupt). It is done by interrupt manager.
2. Register interrupt handler with <b>INITHANDLER</b> macro(takes interrupt number, handler address, [type](http://wiki.osdev.org/Interrupt_Descriptor_Table#Structure)).
3. Enable IRQ interrupt for PICs if necessary, using macros: <b>ENABLE_MASTER_BIT</b>, <b>DISABLE_MASTER_BIT</b>, <b>ENABLE_SLAVE_BIT</b>, <b>DISABLE_SLAVE_BIT</b>.
  To find out bits to enable see table <i>"The 8259 programmable interrupt controller (PIC) chips"</i> [here](http://www.xbdev.net/asm/protected_mode/tut_025/).
