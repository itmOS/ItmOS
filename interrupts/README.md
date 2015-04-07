ItmOS::interrupts
===========

Module for interrupt support.

Tutorial for adding interrupt handler:
--------
1. Write handler body(Ex. <i>timer_int</i>)
2. Wrap it with <b>WRAPHANDLER</b> macro(saves registers, sends EOI(End Of Interrupt)). It's handler you need. (Ex. <i>timer_int_handler</i>)
3. Fill appropriate element of IDT(Interrupt Descriptor Table) with <b>INITHANDLER</b> macro(takes interrupt number, handler address, [type](http://wiki.osdev.org/Interrupt_Descriptor_Table#Structure)).
4. [Enable interrupt for PICs](http://www.xbdev.net/asm/protected_mode/tut_025/) if necessary([IRQs](http://en.wikipedia.org/wiki/Interrupt_request_%28PC_architecture%29)).
