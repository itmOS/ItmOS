ItmOS::interrupts
===========

Module for interrupt support.

Tutorial for adding interrupt handler:
--------
1. Write handler body(Ex. <i>timer_int</i>)
<<<<<<< HEAD
2. Wrap it with <b>WRAPHANDLER</b> macro(saves registers, sends EOI(End Of Interrupt)). It's handler you need. (Ex. <i>timer_int_handler</i>)
3. Fill appropriate element of IDT(Interrupt Descriptor Table) with <b>INITHANDLER</b> macro(takes interrupt number, handler address, [type](http://wiki.osdev.org/Interrupt_Descriptor_Table#Structure)).
4. Enable interrupt for PICs if necessary([IRQs](http://en.wikipedia.org/wiki/Interrupt_request_%28PC_architecture%29)).
=======
2. Wrap it with <b>wrapHandler</b> macro(saves registers, sends EOI(End Of Interrupt)). It's handler you need. (Ex. <i>timer_int_handler</i>)
3. Fill appropriate element of IDT(Interrupt Descriptor Table) with <b>initHandler</b> macro(takes interrupt number, handler address, [type](http://wiki.osdev.org/Interrupt_Descriptor_Table#Structure)).
4. [Enable interrupt for PICs](http://www.xbdev.net/asm/protected_mode/tut_025/) if necessary([IRQs](http://en.wikipedia.org/wiki/Interrupt_request_%28PC_architecture%29)).
>>>>>>> f3fcbe6e36e8c80f71c772d3e141d53f445ccca7
