#ifndef ITMOS_FS_H
#define ITMOS_FS_H
__attribute__((cdecl))
void fat_init();
char* get_bootrecord();
int fat_read(void* this, void* dest, int count);
int fat_write(int fid, int offset, void* src, int count);
struct fdobject* fat_open(const char* path, int flags);

struct __attribute__((__packed__)) fdobject {
    int count;
    int (*read)(void* this, void* buf, int count);
    int (*write)(void* this, void* buf, int count);
    void (*close)(void* this);
};
#endif
