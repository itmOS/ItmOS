%ifndef ATA_INC
%define ATA_INC

extern ata_pio_inbyte
extern ata_pio_outbyte

%macro ATA_PIO_INBYTE 2
	push edi
	mov es, %1
	mov di, %2
	call ata_pio_inbyte
	pop edi
%endmacro

%macro ATA_PIO_OUTBYTE 3
	push eax
	push edi
	mov es, %1
	mov di, %2
	mov al, %3
	call ata_pio_outbyte
	pop edi
	pop eax
%endmacro

%endif
