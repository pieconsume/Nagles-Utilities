%include "../FSUtils.asm"

;Macros
 %assign cursec 0x00
 %define curblk cursec/(blksz/secsz)
 %macro secalign 2.nolist ;Note - Alignment util. Pads 0s until at least N sectors from the previous call have been written.
  ;hexprint cursec, LBA,  %2
  %assign cursec cursec+%1
  times (cursec*secsz)-($-$$) db 0
  %endmacro
 %macro blkalign 2.nolist ;Note - For ext blocks rather than sectors.
  hexprint curblk, Block, %2
  secalign (%1*(blksz/secsz)), %2
  %endmacro
 %macro incalign 3.nolist ;Note - Just incbin then secalign.
  incbin %1
  secalign %2,%3
  %endmacro
 %define vermj 0x0001               ;Major version (1 for extended superblock)
 %define secs  512                  ;Total sectors
 %define secsz 512                  ;Bytes per sector
 %define blksz 4096                 ;Bytes per block
 %assign indsz 0x0080               ;Bytes per inode
 %assign blkct secs / (blksz/secsz) ;Total blocks
 %assign grpct 1                    ;Total groups
 %assign indpb blksz/indsz          ;Inode per block
 %assign indpg blksz                ;Inode per group. Set a default ratio of 1 inode / 8 blocks (assuming full bitmaps)
 %if indpg > blkct                  ;Reduce inodes per group if there are few blocks
  %assign indpg blkct>>3            ;Set 1 inode / 8 blocks
  %if indpg % indpb != 0
   %assign dif indpg % indpb
   %assign indpg (indpg - dif + indpb)
   %endif
  %if indpg == 0
   %assign indpg 1
   %endif
  %endif
 %assign indct indpg*grpct          ;Total inodes
 %assign blknd (indpg*indsz)/blksz  ;Total blocks used for every inode table
 %assign blkdv (blksz / 1024)-1     ;Get bitmask of division
 %assign sbblk  0                   ;Block of superblock
 %assign blksh 0                    ;Block shift
 %rep 32                            ;Get bitshift for block size and fragment size
  %if blkdv == 0
  %exitrep
  %endif
  %assign blkdv blkdv >> 1
  %assign blksh blksh+1
  %endrep
 %if blksz == 1024                  ;The superblock is always at block 0, unless blksz is 1024
  %assign sbblk 1
  %endif
 %warning secsz sector  size
 %warning secs  sectors total
 %warning blksz block   size
 %warning blkct blocks  total
 %warning indsz inode   size
 %warning indct inodes  total
 %warning indpb inodes  per block
 %warning grpct groups
 %warning blknd blocks  per inode table
fsgen:
 %assign idx 1
 %assign blkrs 0x05 ;Reserved blocks
 %assign indrs 0x00 ;Reserved inodes
 %macro mki 0   ;Empty inode entry
  %assign ind%[idx]_type -1
  %assign idx idx+1
  %assign indrs indrs+1
  %endmacro
 %macro mki 3-4 ;Folder/file inode
  %push mac_mki
  ;%1, type
  ;%2, name
  ;%3, parent folder inode
  ;%4, file
  %assign %$par %3
  %assign ind%[idx]_type   %1 ;Set type
  %define ind%[idx]_name   %2 ;Set name
  %assign ind%[idx]_parent %3 ;Set parent
  %if %1 == 0 ;Dir
   %assign ind%[idx]_links 2          ;Set self and parent->child links
   %assign ind%[idx]_chcnt 2          ;Set starting child count
   %define ind%[idx]_child0_name "."  ;Mke .  entry
   %assign ind%[idx]_child0_idx  idx  ;Set .  entry inode index
   %define ind%[idx]_child1_name ".." ;Mke .. entry
   %assign ind%[idx]_child1_idx  %3   ;Set .. entry inode index
   %endif
  %if %1 == 1 ;File
   %assign ind%[idx]_links 1 ;Set parent link
   %define ind%[idx]_file %4
   %endif
  %if %3 != idx ;Create child
   %assign %$chidx ind%[%$par]_chcnt
   %define ind%[%$par]_child%[%$chidx]_name %2   ;Set child name in parent
   %assign ind%[%$par]_child%[%$chidx]_idx  idx  ;Set child name in parent
   %assign ind%[%$par]_chcnt ind%[%$par]_chcnt+1 ;Inc child count in parent
   %if %1 == 0                                   ;Inc links in parent if this is a folder
    %assign ind%[%$par]_links ind%[%$par]_links+1
    %endif
   %endif
  %assign indrs indrs+1
  %assign blkrs blkrs+1
  %assign idx idx+1
  %pop mac_mki
  %endmacro
 ;
 mki                                              ;0x01 Null
 mki 0x00, "Root",       0x02                     ;0x02 Root
 mki                                              ;0x03 Null
 mki                                              ;0x04 Null
 mki                                              ;0x05 Null
 mki                                              ;0x06 Null
 mki                                              ;0x07 Null
 mki                                              ;0x08 Null
 mki                                              ;0x09 Null
 mki                                              ;0x0A Null
 mki 0x00, "lost+found", 0x02                     ;0x0B Lost and found
 mki 0x01, "Test.txt",   0x02, "src/TestFile.txt" ;0x0C Test file
 %assign blkua blkct-blkrs
 %assign indua indct-indrs
 %assign indmk idx-1
pre:
 %ifdef gpt
 incalign "builds/Ext2_MBR", 0x01,Bootloader
 incalign "builds/Ext2_GPTA",0x01,GPT
 incalign "builds/Ext2_GPTE",0x08,GPTA
 %endif
 pre.end:
 ext2:
superblock:   ;0x00
 times 0x400 db 0 ;Reserved space
 dd indct      ;0x0000 Inodes total
 dd blkct      ;0x0004 Blocks total
 dd 0x00000000 ;0x0008 Rsrved blocks
 dd blkua      ;0x000C Blocks unallocated
 dd indua      ;0x0010 Inodes unallocated
 dd sbblk      ;0x0014 Spblk  block
 dd blksh      ;0x0018 Blocks size
 dd blksh      ;0x001C Fragms size
 ;Simplest configuration, but others may be more desirable. One inode for each block is usually excessive
 dd blksz*8    ;0x0020 Blocks per group
 dd blksz*8    ;0x0024 Fragms per group
 dd indpg      ;0x0028 Inodes per group. Cannot be larger than blksz*8, must be divisible by indpb
 dd 0x00000000 ;0x002C Tmstmp last mount
 dd 0x00000000 ;0x0030 Tmstmp last write
 dw 0x0000     ;0x0034 Mount  count
 dw 0xFFFF     ;0x0036 Mount  max allowed
 dw 0xEF53     ;0x0038 Signtr ext2
 dw 0x0000     ;0x003A State  of unmount (0x0001 clean, 0x0002 error)
 dw 0x0000     ;0x003C Errors set (0x01 ignore, 0x02 readonly, 0x03 kernel panic)
 dw 0x0000     ;0x003E Versn  minor
 dd 0x00000000 ;0x0040 Tmstmp last filesystem check
 dd 0x00000000 ;0x0044 Tmstmp max interval of checks
 dd 'NFSU'     ;0x0048 CrtrOS Nagle's FS Utils
 dd vermj      ;0x004C Versn  major. Set 0x01 for the extended superblock
 dw 0x0000     ;0x0050 Rsrvd  user ID
 dw 0x0000     ;0x0052 Rsrvd  group ID
 %if vermj > 0
 dd 0x0000000B ;0x0054 Inodes first valid
 dw 0x0080     ;0x0058 Inodes entry size
 dw 0x0000     ;0x005A Group  current
 dd 0x00000000 ;0x005C Featrs optional
  ;0x00000001 Block pre-allocation for new directories
  ;0x00000002 IMagic inodes
  ;0x00000004 Ext3 journal
  ;0x00000008 Extended inode attributes
  ;0x00000010 Non-standard inode size
  ;0x00000020 H-Tree directory indexing
 dd 0x00000000 ;0x0060 Featrs required
  ;0x00000001 Compression used
  ;0x00000002 Directory type field
  ;0x00000004 Perform journal replay
  ;0x00000008 Journal device
  ;0x00000010 Meta blocks
  ;0x00000040 Extents
  ;0x00000080 64-bit
  ;0x00000100 MMP
  ;0x00000200 Flex block groups
  ;0x00000400 Extended attributes
  ;0x00001000 Data in directory entries
  ;0x00002000 Metadata checksum in superblock
  ;0x00004000 Directories > 4 GiB
  ;0x00008000 Inode data
  ;0x00010000 Encyption
  ;0x00020000 Case folder dd 0x00000000
 dd 0x00000000 ;0x0064 Featrs readonly
  ;0x00000001 Sparse superblock
  ;0x00000002 Large file support
  ;0x00000004 Binary tree sorted directory files
 ddrand        ;0x0068 FSUUID
 ddrand        ;0x006C FSUUID
 ddrand        ;0x0070 FSUUID
 ddrand        ;0x0074 FSUUID
 dd 0x00000000 ;0x0078 Volume name
 dd 0x00000000 ;0x007C Volume name
 dd 0x00000000 ;0x0080 Volume name
 dd 0x00000000 ;0x0084 Volume name
 dd 0x00000000 ;0x0088 Volume last mounted as
 dd 0x00000000 ;0x008C Volume last mounted as
 dd 0x00000000 ;0x0090 Volume last mounted as
 dd 0x00000000 ;0x0094 Volume last mounted as
 dd 0x00000000 ;0x0098 Volume last mounted as
 dd 0x00000000 ;0x009C Volume last mounted as
 dd 0x00000000 ;0x00A0 Volume last mounted as
 dd 0x00000000 ;0x00A4 Volume last mounted as
 dd 0x00000000 ;0x00A8 Volume last mounted as
 dd 0x00000000 ;0x00AC Volume last mounted as
 dd 0x00000000 ;0x00B0 Volume last mounted as
 dd 0x00000000 ;0x00B4 Volume last mounted as
 dd 0x00000000 ;0x00B8 Volume last mounted as
 dd 0x00000000 ;0x00BC Volume last mounted as
 dd 0x00000000 ;0x00C0 Volume last mounted as
 dd 0x00000000 ;0x00C4 Volume last mounted as
 dd 0x00000000 ;0x00C8 Algthm for compression
 db 0x00       ;0x00CC Blocks to preallocate for files
 db 0x00       ;0x00CD Blocks to preallocate for directories
 dw 0x0000     ;0x00CE Rsrved in ext2
 dd 0x00000000 ;0x00D0 Journ  UUID
 dd 0x00000000 ;0x00D4 Journ  UUID
 dd 0x00000000 ;0x00D8 Journ  UUID
 dd 0x00000000 ;0x00DC Journ  UUID
 dd 0x00000000 ;0x00E0 Journ  inode
 dd 0x00000000 ;0x00E4 Journ  device number
 dd 0x00000000 ;0x00E8 Orphan head
 dd 0x8543A660 ;0x00EC HTREE  hash seed (copied from hexdump)
 dd 0xB1CD4F3A ;0x00F0 HTREE  hash seed
 dd 0x9CBAE8E4 ;0x00F4 HTREE  hash seed
 dd 0x5B1ECC20 ;0x00F8 HTREE  hash seed
 db 0x01       ;0x00FC HTREE  hash algorithm
 db 0x00       ;0x00FD Rsrved in ext2
 dw 0x0000     ;0x00FE Rsrved in ext2
 dd 0x00000000 ;0x0100 Mount  options
 dd 0x00000000 ;0x0104 Metabl first group
 %endif
 blkalign 0x01, Superblock
blkdesc:      ;0x01
 dd 0x00000002  ;0x0000 Blocks usage bitmap
 dd 0x00000003  ;0x0004 Inodes usage bitmap
 dd 0x00000004  ;0x0008 Inodes table block
 dw blkua       ;0x000C Blocks unallocated in group
 dw indua       ;0x000E Inodes unallocated in group
 dw 0x0002      ;0x0010 Dircts in group
 dw 0x0000      ;0x0012 Unused in ext2
 blkalign 0x01, Block group descriptor
bitmap_blk:   ;0x02
 ;Note - this could easily be rewritten much better
 %assign blktm blkct ;Blocks to map
 %rep blksz
  %if   blktm != 0
   %if   blkrs >= 8 ;>=8 blocks left to reserve
    db -1                 ;Reserve 8 blocks
    %assign blkrs blkrs-8 ;Reduce reserve count by 8
   %elif blkrs <  8 ;< 8 blocks left to reserve
    db (0x01<<blkrs)-1    ;Get the mask
    %assign blkrs 0       ;Clear reserve count
   %elif blktm >  8 ;> 8 blocks left to map, none left to reserve
    db 0
   %else            ;< 8 blocks left to map. blksz must always be aligned so this is pointless.
    db ~((0x01<<blktm)-1)
    %endif
   %assign blktm blktm-8
  %else
   db -1
   %endif
  %endrep
 blkalign 0x01, Block bitmap
bitmap_inode: ;0x03
 ;Note - this could easily be rewritten much better
 ;Note - same algorithm as bitmap_blk
 %assign blktm indct
 %rep blksz
  %if   blktm != 0
   %if   indrs >= 8
    db -1
    %assign indrs indrs-8
   %elif indrs <  8
    db (0x01<<indrs)-1
    %assign indrs 0
   %elif blktm >  8
    db 0
   %else
    db ~((0x01<<blktm)-1)
    %endif
   %assign blktm blktm-8
  %else
   db -1
   %endif
  %endrep
 blkalign 0x01, Inode bitmap
inode_table:  ;0x04
 %define blk(x) ((x-$$) - (ext2-$$)) / blksz
 %macro inode_ent 0-5 0,0,0,0,0
  dw %1         ;0x00 Type and permissions
  dw 0x0000     ;0x02 UserID
  dd %2         ;0x04 Size lo
  dd 0x00000000 ;0x08 Timestamp
  dd 0x00000000 ;0x0C Timestamp
  dd 0x00000000 ;0x10 Timestamp
  dd 0x00000000 ;0x14 Timestamp
  dw 0x0000     ;0x18 GID
  dw %5         ;0x1A Links
  dd %3/secsz   ;0x1C Sectors
  dd 0x00000000 ;0x20 Flags
  dd 0x00000000 ;0x24 OS1
  dd %4         ;0x28 BlockN
  dd 0x00000000 ;0x2C BlockN
  dd 0x00000000 ;0x30 BlockN
  dd 0x00000000 ;0x34 BlockN
  dd 0x00000000 ;0x38 BlockN
  dd 0x00000000 ;0x3C BlockN
  dd 0x00000000 ;0x40 BlockN
  dd 0x00000000 ;0x44 BlockN
  dd 0x00000000 ;0x48 BlockN
  dd 0x00000000 ;0x4C BlockN
  dd 0x00000000 ;0x50 BlockN
  dd 0x00000000 ;0x54 BlockN
  dd 0x00000000 ;0x58 BlockInd1
  dd 0x00000000 ;0x5C BlockInd2
  dd 0x00000000 ;0x60 BlockInd3
  dd 0x00000000 ;0x64 Generation
  dd 0x00000000 ;0x68 FileACL
  dd 0x00000000 ;0x6C DirACL
  dd 0x00000000 ;0x70 Fragment
  dd 0x00000000 ;0x74 OS2
  dd 0x00000000 ;0x78 OS2
  dd 0x00000000 ;0x7C OS2
  %endmacro
 %assign idx 1
 %push rep_indmk
 %rep indmk
  %if ind%[idx]_type == -1
   inode_ent
  %else
   %define  %$flag %cond(ind%[idx]_type == 0, 0x41ED, 0x81B4) ;Folder/file flags
   %define  %$size   sz(ind%[idx]_fle)                        ;Size of file
   %define  %$blksz  sz(ind%[idx]_blk)                        ;Size of blocks
   %define  %$block blk(ind%[idx]_blk)                        ;Block
   %define  %$links ind%[idx]_links                           ;Links
   %define  %$name  ind%[idx]_name
   %warning %$name blocks %$block
   %warning %$name size   %$size
   %warning %$name links  %$links
   %warning %$name flags  %$flag
   inode_ent %$flag, %$size, %$blksz, %$block, %$links
   %endif
  %assign idx idx+1
  %endrep
  %pop rep_indmk
 blkalign blknd, Inode table
files:        ;0x05
 %macro dirent 2-3.nolist
  %strlen len %2
  %%start:
  dd %1            ;Inode
  dw %%end-%%start ;Total size
  db len           ;Name  size
  db 0             ;Type  (if feature bit is set)
  db %2            ;Name
  align 0x04, db 0 ;Entries are always dword aligned
  %if %0 > 2      ;The final entry must span the entire block
   %deftok name %3
   blkalign 0x01,name
   %endif
  %%end:
  %endmacro
 %assign idx 1
 %push rep_indmk
 %rep indmk
  %if ind%[idx]_type == 0
   %define %$name  ind%[idx]_name  ;Get parent name
   %assign %$chcnt ind%[idx]_chcnt ;Get parent child count
   %assign %$chidx 0
   ind%[idx]_blk:
   ind%[idx]_fle:
   %rep %$chcnt
    %define %$ch_name ind%[idx]_child%[%$chidx]_name ;Get child name
    %assign %$ch_ref  ind%[idx]_child%[%$chidx]_idx  ;Get reference
    %warning %$name Name: %$ch_name Ref: %$ch_ref
    %if %$chidx == %$chcnt-1                         ;Chk final  entry
    dirent %$ch_ref, %$ch_name, %$name               ;Out final  entry
    %else                                            ;Els
    dirent %$ch_ref, %$ch_name                       ;Out normal entry
    %endif                                           ;
    %assign %$chidx %$chidx+1                        ;Inc chidx
    %endrep
   ind%[idx]_fle.end:
   ind%[idx]_blk.end:
   %endif
  %if ind%[idx]_type == 1
   %define %$name  ind%[idx]_name  ;Get parent name
   ind%[idx]_blk:
   ind%[idx]_fle:
   incbin ind%[idx]_file
   ind%[idx]_fle.end:
   blkalign (sz(ind%[idx]_fle) / blksz)+1, %$name
   ind%[idx]_blk.end:
   %endif
  %assign idx idx+1
  %endrep
  %pop rep_indmk
times (blkct*blksz)-($-$$) db 0