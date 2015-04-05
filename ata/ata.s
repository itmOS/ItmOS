global ata_read

section .text
;;; esi -- driver data info
;;; edi -- destionation buffer
;;; bl  -- sectors to read
;;; dx  -- base bus IO port (probably 0x1F0)
;;; ebp -- 28bit relative LBA
ata_read:
	;;; TODO implement
	ret
