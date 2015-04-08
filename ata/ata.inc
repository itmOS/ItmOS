%ifndef ATA_INC
%define ATA_INC

extern ata_pio_inseg
extern ata_pio_outseg
extern ata_identify

%macro ATA_IDENTIFY 0
	call ata_identify
%endmacro

%macro ATA_PIO_INSEG 3
	push ebp
	push edi
	push ebx
	mov ebp, %1
	mov edi, %2
	mov bl, %3
	call ata_pio_inseg
	pop ebx
	pop edi
	pop ebp
%endmacro

%macro ATA_PIO_OUTSEG 3
	push ebp
	push esi
	push ebx
	mov ebp, %1
	mov esi, %2
	mov bl, %3
	call ata_pio_outseg
	pop ebx
	pop esi
	pop ebp
%endmacro

%endif
