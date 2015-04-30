#ifndef ITMOS_FS_H
#define ITMOS_FS_H
__attribute__((cdecl))
void fat_init();
char* get_bootrecord();
int fat_open_ro(char* path);
int fat_read(int fid, void* dest);
int fat_write(int fid, int offset, void* buf, int count);
#endif
