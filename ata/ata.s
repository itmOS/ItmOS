global ata_pio_inseg
global ata_pio_outseg
global ata_identify

%include "tty/tty.inc"
%include "aux/log/log.inc"

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

%define ATA_PORT_CTRL 0x3f6 ; Device control register

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

;;; Control register bits
%define ATA_DCR_NIEN 0x02 ;; Disables IRQ sending
%define ATA_DCR_SRST 0x04 ;; Software reset on all ATA devices on a bus
%define ATA_DCR_HOB  0x80 ;; Set this to read back the High Order Byte of the
                          ;; last LBA48 value sent to an I/O port (I don't know
                          ;; why I need this)

;;; HD IDs
%define ATA_CHS_MASTER 0xA0   ;; Oldest type (doesn't supported at this moment)
%define ATA_LBA28_MASTER 0xE0 ;; Supported by almost all hard disks
%define ATA_LBA48_MASTER 0x40 ;; Current standard of hard disks (doesn't
                              ;; supported yet)

;;; HD commands
%define ATA_CMD_READ         0x20
%define ATA_CMD_WRITE        0x30
%define ATA_CMD_FLUSH_CACHE  0xE7
%define ATA_CMD_IDENTIFY     0xEC

;;; Return codes
%define ATA_OK       0
%define ATA_BAD      1
%define ATA_NO_DRIVE 2
%define ATA_NOT_ATA  3

section .text

ata_identify:
	mov al, ATA_CHS_MASTER
	mov dx, ATA_PIO_BASE_ADDR
	or dx, ATA_PIO_PORT_DRV_HEAD
	out dx, al
	xor eax, eax
	mov dx, ATA_PIO_BASE_ADDR
	or dx, ATA_PIO_PORT_SECT_COUNT
	out dx, al
	inc dx
	out dx, al
	inc dx
	out dx, al
	inc dx
	out dx, al
	mov dx, ATA_PIO_BASE_ADDR
	or dx, ATA_PIO_PORT_COMMAND
	mov al, ATA_CMD_IDENTIFY
	out dx, al
	in al, dx
	cmp al, 0
	jnz .check_drive
	LOG_ERR ata_pio_no_drive_log
	mov al, ATA_NO_DRIVE
	jmp .return
.check_drive
	LOG_OK ata_pio_yes_drive_log

	mov dx, ATA_PIO_BASE_ADDR
	add dx, ATA_PIO_PORT_STATUS
	mov ecx, 4            ; we need to repeat this at most 4 times
.wait
	in al, dx              ; read status byte
	test al, ATA_ST_BSY    ; wait until BSY flag is cleared
	je .cleared
	loop .wait
.cleared
	mov dx, ATA_PIO_BASE_ADDR
	add dx, ATA_PIO_PORT_CYL_LOW
	in al, dx
	cmp al, 0
	jne .not_ata
	inc dx
	in al, dx
	cmp al, 0
	jne .not_ata
	LOG_OK ata_pio_ata_drive_log
	;mov dx, ATA_PIO_BASE_ADDR
	;add dx, ATA_PIO_PORT_STATUS
;.poll
	;in al, dx
	;test al, ATA_ST_BSY
	;je .poll
	;test al, ATA_ST_DRQ

	jmp .return
.not_ata
	LOG_ERR ata_pio_not_ata_drive_log
	mov al, ATA_NOT_ATA
.return
	ret

;;; Does soft reset on both ATA devices
ata_reset:
	push edx
	push eax
	mov dx, ATA_PORT_CTRL
	mov al, ATA_DCR_SRST
	out dx, al ; do a soft reset on the bus
	xor eax, eax
	out dx, al
	in al, dx ; 400ns delay for status bit to reset
	in al, dx
	in al, dx
	in al, dx
	mov dx, ATA_PIO_BASE_ADDR
.loop
	in al, dx
	and al, ATA_ST_BSY | ATA_ST_RDY
	cmp al, ATA_ST_RDY ;; we need BSY flag to be clear
	                   ;; and RDY flag to be set
	jne .loop
	pop eax
	pop edx
	ret

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

	LOG_OK ata_pio_ready_log
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
	LOG_ERR ata_pio_fail_log
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

	LOG_OK ata_pio_ready_log
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
	LOG_ERR ata_pio_fail_log
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
	LOG_OK ata_pio_polling_log
	in al, dx              ; read status byte
	test al, ATA_ST_BSY    ; wait until BSY flag is cleared
	jne .wait_more
	test al, ATA_ST_DRQ    ; test if DRQ flag is set
	jne .okay
.wait_more
	loop .wait

.wait_some_more
	LOG_WARN ata_pio_polling_log
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

ata_pio_ready_log:          db 'ATA_PIO: Ready', 0
ata_pio_fail_log:           db 'ATA_PIO: Fail', 0

ata_pio_polling_log:        db 'ATA_PIO: Polling...', 0

ata_pio_no_drive_log:       db 'ATA_PIO: Drive doesnt exist', 0
ata_pio_yes_drive_log:      db 'ATA_PIO: Drive exists', 0
ata_pio_not_ata_drive_log:  db 'ATA_PIO: Drive is not ATA', 0
ata_pio_ata_drive_log:      db 'ATA_PIO: Drive is ATA', 0

ata_pio_debug:              db 'ATA_PIO_DEBUG: %u', 10, 0