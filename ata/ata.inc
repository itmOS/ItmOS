%ifndef ATA_INC
%define ATA_INC

extern ata_rd_segs
extern ata_wr_segs
extern ata_identify

%macro ATA_IDENTIFY 0
	call ata_identify
%endmacro

%macro ATA_INSEG 3
	push ebp
	push edi
	push ebx
	push dword %3
	push dword %2
	push dword %1
	call ata_rd_segs
    add esp, 12
	pop ebx
	pop edi
	pop ebp
%endmacro

%macro ATA_OUTSEG 3
	push ebp
	push esi
	push ebx
    push dword %3
    push dword %2
    push dword %1
	call ata_wr_segs
    add esp, 12
	pop ebx
	pop esi
	pop ebp
%endmacro

%endif
