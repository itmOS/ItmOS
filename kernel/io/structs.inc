%ifndef KERNEL_IO_STRUCTS_INC
%define KERNEL_IO_STRUCTS_INC

MAX_FD_COUNT: equ 256

;;; Struct representing some opened file descriptor info
;;; Pointer to this structure can be shared between some processes
struc fd_obj
;; Owners counter (like std::shared_ptr)
;; int counter;
.counter: resd 1

;; Pointers to the io methods.
;; int (*read)(fd_obj* this, void* buf, size_t count);
.read: resd 1

;; int (*write)(fd_obj* this, void* buf, size_t count);
.write: resd 1

;; int (*close)(fd_obj* this);
.close: resd 1

;; All the rest is the object's private data
.data: resd 0
endstruc

%endif
