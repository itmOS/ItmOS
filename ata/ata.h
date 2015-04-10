#ifdef ATA_H
#define ATA_H
__attribute__((cdecl))
int ata_rd_segs(int lba28, size_t count, char *data);
int ata_wr_segs(int lba28, size_t count, char *data);
#endif
