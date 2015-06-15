%ifndef SYSCALLS_INC
%define SYSCALLS_INC

%include "kernel/syscalls/macro.inc"

;; void init_syscalls();
;; Initialize all syscalls
extern init_syscalls

%endif
