%ifndef ATA_INC
%define ATA_INC

extern ata_rd_segs
extern ata_wr_segs
extern ata_identify

;;; void ATA_IDENTIFY()
;;; Fetchs disk's information, that will be used later.
;;; Must be called before any read\write.
%macro ATA_IDENTIFY 0
	call ata_identify
%endmacro

;;; void ATA_INSEG(uint32 sector_number, uint32 number_of_sectors, char* destination)
;;; Reads 256 words from all specified sectors (sector_number, sector_number + 1, ..., sector_number + number_of_sectors)
;;; and stores data to destination.
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

;;; void ATA_OUTSEG(uint32 sector_number, uint32 number_of_sectors, char* source)
;;; Writes 256 words to all specified sectors (sector_number, sector_number + 1, ..., sector_number + number_of_sectors).
;;; Data will be recieved from source.
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
