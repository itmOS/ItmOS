global ata_pio_inbyte
global ata_pio_outbyte

;;; Shitty implementation of ATA driver. All errors (CRC and other) are ignored
;;; at this moment.

section .text
;;; Reads byte from specified address. (Uses pio_base_addr as device)
;;; Input:
;;;   es -- segment number
;;;   di -- segment offset
;;; Output:
;;;		al -- result of reading from specified address
ata_pio_inbyte:
	push edx

	mov dx, [pio_base_addr]

	in al, dx

	pop edx
	ret

;;; Writes byte to specified address. (Uses pio_base_addr as device)
;;; Input:
;;;		al -- byte to write
;;;   es -- segment number
;;;   di -- segment offset
ata_pio_outbyte:
	push edx

	mov dx, [pio_base_addr]
	add dx, cx

	out dx, al

	pop edx
	ret



section .data
;;; Primary bus I/O port. Other ports are specified as
;;; offset from this one.
pio_base_addr: dd 0x1F0
;;; 9 I/O ports, which control ATA bus behaviour.
;;; For the primary bus, these I/O ports are 0x1F0
;;; through 0x1F9.
cb_data:  db 0 ;;; data reg      in/out
cb_err:	  db 1 ;;; error         in
cb_fr:    db 1 ;;; feature reg      out
cb_sc:    db 2 ;;; sector count  in/out
cb_sn:    db 3 ;;; sector number in/out
cb_cl:    db 4 ;;; cylinder low  in/out
cb_ch:    db 5 ;;; cylinder high in/out
cb_dh:    db 6 ;;; device head   in/out
cb_stat:  db 7 ;;; prim status   in
cb_cmd:   db 7 ;;; command          out
cb_astat: db 8 ;;; alt status    in
cb_dc:    db 8 ;;; device ctrl      out
cb_da:    db 9 ;;; device addr   in
