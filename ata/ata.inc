%ifndef ATA_INC
%define ATA_INC

extern ata_pio_inbyte
extern ata_pio_outbyte

%macro ATA_PIO_INBYTE 1
	push ebp
	push edx
	push ecx
	mov ebp, %1
	call ata_pio_inbyte
	pop ecx
	pop edx
	pop ebp
%endmacro

%macro ATA_PIO_OUTBYTE 2
	push ebp
	push ebx
	mov ebp, %1
	mov bl, %2
	call ata_pio_outbyte
	pop ebx
	pop ebp
%endmacro

%endif
