global ata_pio_inseg
global ata_pio_outseg

%include "tty/tty.inc"

;;; Shitty implementation of ATA driver. Errors are handled, but nothing can be
;;; done with them at this moment.

;;; Primary bus I/O port. Other ports are specified as
;;; offset from this one.
%define ATA_PIO_BASE_ADDR 0x1f0

%define ATA_PIO_PORT_DATA        0
%define ATA_PIO_PORT_ERROR       1
%define ATA_PIO_PORT_SECT_COUNT  2
%define ATA_PIO_PORT_SECT_NUM    3
%define ATA_PIO_PORT_CYL_LOW     4
%define ATA_PIO_PORT_CYL_HIGH    5
%define ATA_PIO_PORT_DRV_HEAD    6
%define ATA_PIO_PORT_STATUS      7
%define ATA_PIO_PORT_COMMAND     7

;;; Status reg's bits
%define ATA_ST_ERR 0x01 ;; Indicates an error occurred. Send a new command
                        ;; to clear it (or nuke it with a Software Reset).

                        ;; Bits 1 and 2 are something unimportant

%define ATA_ST_DRQ 0x08 ;; Set when the drive has PIO data to transfer, or is
                        ;; ready to accept PIO data
%define ATA_ST_SRV 0x10 ;; Overlapped Mode Service Request
%define ATA_ST_DF  0x20 ;; Drive Fault Error (does not set ERR)
%define ATA_ST_RDY 0x40 ;; Bit is clear when drive is spun down, or after an
                        ;; error. Set otherwise.
%define ATA_ST_BSY 0x80 ;; Indicates the drive is preparing to send/receive data
                        ;; (wait for it to clear). In case of 'hang' (it never clears), do a software
                        ;; reset.

;;; HD IDs
%define ATA_LBA28_MASTER 0xE0

;;; HD commands
%define ATA_CMD_READ         0x20
%define ATA_CMD_WRITE        0x30
%define ATA_CMD_FLUSH_CACHE  0xE7

;;; Return codes
%define ATA_OK  0
%define ATA_BAD 1


section .text
;;; Reads byte from specified address. (Uses pio_base_addr as device)
;;; Input:
;;;   ebp -- absolute lba
;;;   edi -- result buffer
;;;   bl  -- number of sectors to read
ata_pio_inseg:
	TTY_SET_STYLE TTY_STYLE (TTY_RED, TTY_BLUE)
	push ebp
	push ata_pio_inbyte_log
	TTY_PRINTF
	pop ebp
	pop ebp
.read
	xor eax, eax
	mov ecx, ebp
	mov al, 1    ; number of sectors to read

	mov dx, ATA_PIO_BASE_ADDR
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
	or al, ATA_LBA28_MASTER
	inc edx      ; bits 24..28
	             ; TODO: probably master\slave flag to check
	out dx, al

	inc edx      ; command/status port 0x1f7
	mov al, ATA_CMD_READ ; send "read" command
	out dx, al

	call ata_poll
	cmp al, ATA_OK
	jne .failed

	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_ready_log
	sub dl, 7     ; return to 0x1f0

	mov ecx, 256
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
	pop eax
	pop eax

	test al, ATA_ST_DF | ATA_ST_ERR
	jne .failed

	inc ebp
	dec ebx
	test bl, bl
	jne .read

	jmp .success
.failed
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_fail_log
	stc
.success
	ret

;;; Writes byte to specified address. (Uses pio_base_addr as device)
;;; Input:
;;;		esi  -- buffer to write
;;;   ebp  -- absolute lba
;;;   bl   -- number of sectors to write
ata_pio_outseg:
	TTY_SET_STYLE TTY_STYLE (TTY_RED, TTY_BLUE)
	push ebp
	push ata_pio_outbyte_log
	TTY_PRINTF
	pop ebp
	pop ebp
.write
	xor eax, eax
	mov ecx, ebp
	mov al, 1    ; number of sectors to read

	mov dx, ATA_PIO_BASE_ADDR
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
	or al, ATA_LBA28_MASTER  ; 0xE0 for LBA28
	inc edx      ; bits 24..28
	             ; TODO: probably master\slave flag to check
	out dx, al

	inc edx      ; command/status port 0x1f7
	mov al, ATA_CMD_WRITE ; send "write" command
	out dx, al

	call ata_poll
	cmp al, ATA_OK
	jne .failed

	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_ready_log
	sub dl, 7     ; return to 0x1f0

	mov ecx, 256
	cld
.loop
	outsw
	xor eax, eax ; small delay (we don't want to output too fast)
	loop .loop
	or dl, 7
	mov al, ATA_CMD_FLUSH_CACHE
	out dx, al

	in al, dx     ; godlike ATA interface
	in al, dx     ; 400ns delay is the best thing i ever saw
	in al, dx     ; wow it's so cool
	in al, dx

	push eax
	push ata_pio_write_log
	TTY_PRINTF
	pop eax
	pop eax

	test al, ATA_ST_DF | ATA_ST_ERR
	jne .failed

	inc ebp
	dec ebx
	test bl, bl
	jne .write

	jmp .success
.failed
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_fail_log
	stc
.success
	ret

;;; Waits until drive is ready before transfering data as
;;; specified in documentation
ata_poll:
	push edx
	push ecx
	xor eax, eax
	mov dx, ATA_PIO_BASE_ADDR
	add dx, ATA_PIO_PORT_STATUS
	mov ecx, 4            ; we need to repeat this at most 4 times
.wait
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_polling_log
	in al, dx              ; read status byte
	test al, ATA_ST_BSY    ; wait until BSY flag is cleared
	jne .wait_more
	test al, ATA_ST_DRQ    ; test if DRQ flag is set
	jne .okay
.wait_more
	loop .wait

.wait_some_more
	TTY_PUTS_STYLED TTY_STYLE(TTY_RED, TTY_BLUE), ata_pio_polling_log
	in al, dx                       ; read status byte
	test al, ATA_ST_BSY             ; wait until BSY flag is cleared
	jne .wait_some_more
	test al, ATA_ST_DF | ATA_ST_ERR ;; test for ERR and DF flags
	                                ;; Specification says, that ERR and DF
	                                ;; together or DRQ must be cleared
	jne .failed
	jmp .okay
.failed
	mov al, ATA_BAD
	jmp .return
.okay
	mov al, ATA_OK
.return
	pop ecx
	pop edx
	ret

section .data

;;; Log string
ata_pio_inbyte_log:         db 'ATA_PIO: Inbyte LBA: %u', 10, 0
ata_pio_read_log:           db 'ATA_PIO: Read status code %u', 10, 0

ata_pio_outbyte_log:        db 'ATA_PIO: Outbyte LBA: %u', 10, 0
ata_pio_write_log:          db 'ATA_PIO: Write status code %u', 10, 0

ata_pio_ready_log:          db 'ATA_PIO: Ready', 10, 0
ata_pio_fail_log:           db 'ATA_PIO: Fail', 10, 0

ata_pio_polling_log:        db 'ATA_PIO: Polling...', 10, 0

ata_pio_debug:              db 'ATA_PIO_DEBUG: %u', 10, 0
