%ifndef ATA_INC
%define ATA_INC

extern ata_pio_inbyte
extern ata_pio_outbyte

%macro ATA_PIO_INBYTE 1
	push ecx
	mov cx, %1
	call ata_pio_inbyte
	pop ecx
%endmacro

%macro ATA_PIO_OUTBYTE 2
	push ecx
	push eax
	mov cx, %1
	mov al, %2
	call ata_pio_outbyte
	pop eax
	pop ecx
%endmacro

%endif
