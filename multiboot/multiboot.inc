extern bootinfo_addr

;; Copy boot info to the safe place in .bss. Supposed to be used only once at some early boot
;; stage.
%macro BOOTINFO_LOAD %1
mov edi, bootinfo_addr
mov ecx, 45
rep movsw %1, edi
%endmacro

;; Test whether some bootinfo part is provided.
;; Perform this before accessing the information you wanted!
%macro BOOTINFO_TEST_FLAG %1
test dword [bootinfo_addr], (1 << %1)
%endmacro

;; Feature numbers to be used by BOOTINFO_TEST_FLAG
BOOTINFO_MEMBOUNDS equ 0
BOOTINFO_BOOTDEVICE equ 1
BOOTINFO_CMDLINE equ 2
BOOTINFO_MODULES equ 3
BOOTINFO_SYMTABLE equ 4
BOOTINFO_ELFTABLE equ 5
BOOTINFO_BIOS_MMAP equ 6
BOOTINFO_DRIVES equ 7
BOOTINFO_BIOSCONF equ 8
BOOTINFO_MULTIBOOTNAME equ 9
BOOTINFO_APM equ 10
BOOTINFO_VBE equ 11

%macro BOOTINFO_LOAD_OFFSET 2
mov %2, bootinfo_addr + %1
%endmacro

;; Lower memory bound in kb. Anything below this address may be used for DMA or something
%define BOOTINFO_GET_MEMLOWER BOOTINFO_LOAD_OFFSET 4

;; The first upper memory address in bytes, relative to 1MB
%define BOOTINFO_GET_MEMUPPER BOOTINFO_LOAD_OFFSET 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       Boot Device Info                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define BOOTINFO_GET_BOOTDEVICE BOOTINFO_LOAD_OFFSET 12

;; Load boot device subsubpartition number (0xFF if invalid; see the specification)
%define BOOTINFO_GET_BOOTDEV_SUBSUBPART BOOTINFO_GET_BOOTDEVICE

;; Load boot device subpartition number (0xFF if invalid; see the specification)
%define BOOTINFO_GET_BOOTDEV_SUBPART BOOTINFO_LOAD_OFFSET 13

;; Load boot device DOS partition number
%define BOOTINFO_GET_BOOTDEV_DOSPART BOOTINFO_LOAD_OFFSET 14

;; Load boot device BIOS number (returned by INT 0x13 in real mode; see the specification)
%define BOOTINFO_GET_BOOTDEV_BIOSNUM BOOTINFO_LOAD_OFFSET 15

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Load address of a kernel cmdline (C string)
%define BOOTINFO_GET_CMDLINE BOOTINFO_LOAD_OFFSET 16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Operating system modules                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Load the modules count
%define BOOTINFO_GET_MODS_COUNT BOOTINFO_LOAD_OFFSET 20

;; Load the first module struct pointer
%define BOOTINFO_GET_MODS_ITER BOOTINFO_LOAD_OFFSET 24

;; Module structure fields:
%define BOOTINFO_MOD_START(a) = [a]    ; start address
%define BOOTINFO_MOD_END(a) = [a + 4]  ; end address
%define BOOTINFO_MOD_NAME(a) = [a + 8] ; module name (C string)

;; Get next module structure
%macro BOOTINFO_NEXT_MODULE %1
add %1, 16
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Symbol table of kernel binary
;; TODO something more precise about it?
%define BOOTINFO_GET_SYMTABLE BOOTINFO_LOAD_OFFSET 28

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 Memory map provided by BIOS                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Number of memory map structures
%define BOOTINFO_GET_MMAP_LENGTH BOOTINFO_LOAD_OFFSET 44

;; The first memory map structure
%define BOOTINFO_GET_MMAP_ITER BOOTINFO_LOAD_OFFSET 48

;; Memory map structure fields:
%define BOOTINFO_MMAP_BASEADDR(a) [a + 4] ; Base address of the region
%define BOOTINFO_MMAP_LENGTH(a) [a + 12]  ; Region length
%define BOOTINFO_MMAP_TYPE(a) [a + 20]    ; 1 for RAM, other for reserved

;; Get next memory map structure
%macro BOOTINFO_MMAP_NEXT %1
add %1, dword [%1]
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Available disk drives                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Number of drive structures
%define BOOTINFO_GET_DRIVES_LENGTH BOOTINFO_LOAD_OFFSET 52

;; The first drive structure
%define BOOTINFO_GET_DRIVES_ITER BOOTINFO_LOAD_OFFSET 56

;; Drive structure fields:
%define BOOTINFO_DRIVE_NUMBER(a) [a + 4]
%define BOOTINFO_DRIVE_MODE(a) [a + 5]
%define BOOTINFO_DRIVE_CYLINDERS(a) [a + 6]
%define BOOTINFO_DRIVE_HEADS(a) [a + 8]
%define BOOTINFO_DRIVE_SECTORS(a) [a + 9]

;; Drive IO ports (a null-terminated list)
%define BOOTINFO_DRIVE_PORTS_ITER(a) [a + 10] ; Effective address of the first port entry
%define BOOTINFO_DRIVE_PORTS_NEXT(a) [a + 1]  ; Iterate through ports (effective address again)

;; Next drive structure
%macro BOOTINFO_DRIVES_NEXT %1
add %1, dword [%1]
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; BIOS configuration table (retrieved by GET CONFIGURATION real mode call)
%define BOOTINFO_GET_BIOS_CONFTABLE BOOTINFO_LOAD_OFFSET 60

;; Boot loader name (C string)
%define BOOTINFO_GET_BOOTLOADER_NAME BOOTINFO_LOAD_OFFSET 64

;; APM table
;; TODO maybe get to know something specific about it?
%define BOOTINFO_GET_APM_TABLE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                          VBE Info                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; VBE control info
%define BOOTINFO_GET_VBE_CONTROL BOOTINFO_LOAD_OFFSET 72

;; VBE move info
%define BOOTINFO_GET_VBE_MODEINFO BOOTINFO_LOAD_OFFSET 76

;; VBE mode (format specified in VBE 3.0 specification)
%define BOOTINFO_GET_VBE_MODE BOOTINFO_LOAD_OFFSET 80

;; VBE 2.0+ interface (VBE 3.0 not supported)
%define BOOTINFO_GET_VBE_INTERFACE_SEG BOOTINFO_LOAD_OFFSET 82
%define BOOTINFO_GET_VBE_INTERFACE_OFFSET BOOTINFO_LOAD_OFFSET 84
%define BOOTINFO_GET_VBE_INTERFACE_LENGTH BOOTINFO_LOAD_OFFSET 86
