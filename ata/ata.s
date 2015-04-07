global ata_pio_inbyte
global ata_pio_outbyte

%include "tty/tty.inc"

;;; Shitty implementation of ATA driver. All errors (CRC and other) are ignored
;;; at this moment.

section .text
;;; Reads byte from specified address. (Uses pio_base_addr as device)
;;; Input:
;;;   ebp -- absolute lba
;;; Output:
;;;		al  -- result of reading from specified address
ata_pio_inbyte:
	TTY_SET_STYLE TTY_STYLE (TTY_RED, TTY_BLUE)
	push ebp
	push ata_pio_inbyte_log
	TTY_PRINTF
	pop ebp
	pop ebp
	xor eax, eax
	mov ecx, ebp
	mov al, 1    ; number of sectors to read

	mov dx, [pio_base_addr]
	or dl, 2     ; sector number port (0x1f2)
	out dx, al

	mov al, cl   ; write LBAlow to port 0x1f3
	inc edx      ; bits 0...7
	out dx, al

	mov al, ch   ; write LDAmid to port 0x1f4
	inc edx      ; bits 8...15
	out dx, al

	bswap ecx

	mov al, ch   ; write LDAhigh to port 0x1f5
	inc edx      ; bits 16...23
	out dx, al

	mov al, cl   ; bits 24..32
	and al, 0x0F ; leave only lowest 4 bits (24..28)
	or al, 0xE0  ; 0xE0 for lba28
	inc edx      ; bits 24..28
	             ; probably master\slave flag to check
	out dx, al

	inc edx      ; command/status port 0x1f7
	mov al, 0x20 ; send "read" command
	out dx, al

	mov ecx, 4
.wait
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_waiting_log
	in al, dx     ; read status byte
	test al, 0x80 ; test for BSY flag
	jne .wait_more
	test al, 8    ; test for DRQ flag
	jne .ready
.wait_more
  dec ecx
  jg .wait

.wait_some_more
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_wait_some_more_log
	in al, dx     ; read status byte
	test al, 0x80 ; test for BSY flag
	jne .wait_some_more
	test al, 0x21 ; test for ERR flag
	jne .failed

.ready
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_ready_log
	sub dl, 7     ; return to 0x1f0

	mov ecx, 256
	mov edi, ata_buf
	xor ax, ax
	rep stosw

	mov ecx, 5
	mov edi, ata_buf
	cld
	rep insw
	or dl, 7
	in al, dx     ; godlike ATA interface
	in al, dx     ; 400ns delay is the best thing i ever saw
	in al, dx     ; wow it's so cool
	in al, dx

	push eax
	push ata_pio_read_log
	TTY_PRINTF
	pop ecx
	pop eax

	test al, 0x21
	je .success
.failed
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_fail_log
	stc
.success
	mov al, [ata_buf]
	ret

;;; Writes byte to specified address. (Uses pio_base_addr as device)
;;; Input:
;;;		bl  -- byte to write
;;;   ebp -- absolute lba
ata_pio_outbyte:
	TTY_SET_STYLE TTY_STYLE (TTY_RED, TTY_BLUE)
	push ebp
	push ata_pio_outbyte_log
	TTY_PRINTF
	pop ebp
	pop ebp
	xor eax, eax
	mov ecx, ebp
	mov al, 1    ; number of sectors to read

	mov dx, [pio_base_addr]
	or dl, 2     ; sector number port (0x1f2)
	out dx, al

	mov al, cl   ; write LBAlow to port 0x1f3
	inc edx      ; bits 0...7
	out dx, al

	mov al, ch   ; write LBAmid to port 0x1f4
	inc edx      ; bits 8...15
	out dx, al

	bswap ecx

	mov al, ch   ; write LBAhigh to port 0x1f5
	inc edx      ; bits 16...23
	out dx, al

	mov al, cl   ; bits 24..32
	and al, 0x0F ; leave only lowest 4 bits (24..28)
	or al, 0xE0  ; 0xE0 for LBA28
	inc edx      ; bits 24..28
	             ; probably master\slave flag to check
	out dx, al

	inc edx      ; command/status port 0x1f7
	mov al, 0x30 ; send "write" command
	out dx, al

	mov ecx, 4
.wait
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_waiting_log
	in al, dx     ; read status byte
	test al, 0x80 ; test for BSY flag
	jne .wait_more
	test al, 8    ; test for DRQ flag
	jne .ready
.wait_more
  dec ecx
  jg .wait

.wait_some_more
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_wait_some_more_log
	in al, dx     ; read status byte
	test al, 0x80 ; test for BSY flag
	jne .wait_some_more
	test al, 0x21 ; test for ERR flag
	jne .failed

.ready
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_ready_log
	sub dl, 7     ; return to 0x1f0

	mov cx, 256
	mov edi, ata_buf
	xor ax, ax
	rep stosw

	mov cx, 5
	mov esi, ata_buf
	rol ebx, 16
	xor bx, bx
	rol ebx, 16
	mov [esi], ebx
	cld
	mov cx, 256
.loop2
	outsw
	xor eax, eax
	loop .loop2

	mov dx, 0x1f7
	mov al, 0xE7
	out dx, al

	in al, dx     ; godlike ATA interface
	in al, dx     ; 400ns delay is the best thing i ever saw
	in al, dx     ; wow it's so cool
	in al, dx

	push eax
	push ata_pio_write_log
	TTY_PRINTF
	pop ebx
	pop eax

	test al, 0x21
	je .success
.failed
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_fail_log
	stc
.success
	mov al, [ata_buf]
	ret

section .data
;;; Primary bus I/O port. Other ports are specified as
;;; offset from this one.
pio_base_addr: dw 0x1f0
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

ata_pio_inbyte_log:         db 'ATA_PIO: Inbyte LBA: %u', 10, 0
ata_pio_ready_log:          db 'ATA_PIO: Ready', 10, 0
ata_pio_fail_log:           db 'ATA_PIO: Fail', 10, 0
ata_pio_waiting_log:        db 'ATA_PIO: Waiting...', 10, 0
ata_pio_wait_some_more_log: db 'ATA_PIO: Wait some more', 10, 0
ata_pio_read_log:           db 'ATA_PIO: Read status code %u', 10, 0

ata_pio_outbyte_log:        db 'ATA_PIO: Outbyte LBA: %u', 10, 0
ata_pio_write_log:          db 'ATA_PIO: Write status code %u', 10, 0

ata_buf: times 300 dw 0
