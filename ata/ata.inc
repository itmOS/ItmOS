%ifndef ATA_INC
%define ATA_INC

extern ata_pio_inseg
extern ata_pio_outseg

%macro ATA_PIO_INSEG 2
	push ebp
	push edi
	mov ebp, %1
	mov edi, %2
	call ata_pio_inseg
	pop edi
	pop ebp
%endmacro

%macro ATA_PIO_OUTSEG 2
	push ebp
	push esi
	mov ebp, %1
	mov esi, %2
	call ata_pio_outseg
	pop esi
	pop ebp
%endmacro

%endif
