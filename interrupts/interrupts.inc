%ifndef INTERRUPTS_EXTERN_INC
%define INTERRUPTS_EXTERN_INC

%include "interrupts_macro.inc"

extern init_interrupts
extern interrupt_manager
extern interrupt_handlers
extern interrupt_table 


extern MASTER_PIC_MASK
extern SLAVE_PIC_MASK

%endif ; INTERRUPTS_EXTERN_INC
