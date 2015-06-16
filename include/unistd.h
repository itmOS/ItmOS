#ifndef UNISTD_H
#define UNISTD_H

#include <sys/types.h>

ssize_t read(int fd, void* buf, size_t count);
ssize_t write(int fd, void* bug, size_t count);
int close(int fd);

int pipe(int pipefd[2]);

#endif
