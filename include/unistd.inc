%ifndef UNISTD_INC
%define UNISTD_INC

;;; ssize_t read(int fd, void* buf, size_t count);
extern read
;;; ssize_t write(int fd, void* bug, size_t count)
extern write
;;; int close(int fd)
extern close

extern pipe

%endif
