;Macros
 %include "../FSUtils.asm"
 %defstr hexdef 0123456789ABCDEF
 %assign cursec 0x00
 %macro secalign 2.nolist ;Note - Alignment util. Pads 0s until at least N sectors from the previous call have been written.
  hexprint cursec, LBA, %2
  %assign cursec cursec+%1
  times (cursec*bps)-($-$$) db 0
  %endmacro
 %macro incalign 3.nolist ;Note - Just incbin then secalign.
  incbin %1
  secalign %2,%3
  %endmacro
 hexprint secs, Sectors in partition
 hexprint bps,  Bytes per sector
 hexprint spc,  Sectors per cluster
 %assign bpc   bps*spc               ;Bytes   per cluster
 %assign spf   (secs/spc/bps*0x04)   ;Sectors per FAT
pre:
 %ifdef gpt
 incalign "builds/Fat32_MBR", 0x01,Bootloader
 incalign "builds/Fat32_GPTA",0x01,GPT
 incalign "builds/Fat32_GPTE",0x08,GPTE
 %endif
 pre.end:
head:
 %macro fathead 1.nolist
  ;BPB
  db 0xEB,0x58,0x90    ;0x00 Jump code
  dq 'MSWIN4.1'        ;0x03 OEM name
  dw bps               ;0x0B Bytes per sector
  db spc               ;0x0D Sectors per cluster
  dw (fat-head)/bps    ;0x0E Reserved sector count, sectors between the BPB and the FAT
  db 0x02              ;0x10 Number of FATs
  dw 0x0000            ;0x11 Ignored
  %if secs < 0xFFFF    ;0x13 Note - According to the FAT32 specification a FAT32 drive should always have > 0xFFF4 clusters.
  dw secs              ;0x13 Sector count (FAT12/16)
  %else                ;0x13 Note - Smaller FAT32 partitions are fairly compatible, working with most software I've tested.
  dw 0                 ;0x13 Note - Specifically this works with standard linux tools such as fsck.vfat, parted, fdisk, etc and mounts fine.
  %endif               ;0x13 Note - Small FAT32 partitions can also work as EFI boot partitions on both OVMF and real hardware, although this specific genertor hasn't been tested.
  db 0xF0              ;0x15 Media type
  dw 0x0000            ;0x16 Ignored
  dw 0x0000            ;0x18 Ignored
  dw 0x0000            ;0x1A Ignored
  dd sz(pre)/bps       ;0x1C Number of hidden sectors (sectors before the BPB)
  %if secs > 0xFFFF    ;0x20 Note - Continuing from above. The sector count values do not matter according to the spec. Only cluster count.
  dd secs              ;0x20 Sector count (FAT32)
  %else                ;0x20 Note - However, this system for determination sucks because it's very confusing and completely arbitrary.
  dd 0x00000000        ;0x20 Note - Because of that many people (nearly everyone as far as I can tell) completely ignored it.
  %endif               ;0x20 Note - Given that I would consider small FAT32 partitions as a valid pseudo-standard. Thank you for coming to my TED talk.
  dd spf               ;0x24 Sectors per FAT
  dw 0x0000            ;0x28 Flags
  dw 0x0000            ;0x2A File system version (0.0)
  dd 0x00000002        ;0x2C Root cluster
  dw 0x0001            ;0x30 FSInfo location
  dw 0x0006            ;0x32 Backup boot sector
  times 12 db 0x00     ;0x34 Reserved
  db 0x00              ;0x40 Physical Drive Number
  db 0x00              ;0x41 Reserved
  db 0x29              ;0x42 Extended boot signature
  dd 0x564FB32A        ;0x43 Volume ID
  db 'NagleF32   '     ;0x47 Volume label
  db "FAT32   "        ;0x52 File system type
  secalign 0x01,BPB_%1
  ;FSInfo
  dd 0x41615252         ;Signature
  times 0x1E0 db 0      ;Reserved
  dd 0x61417272         ;Signature 2
  dd 0xFFFFFFFF         ;Last known free sector (unknown)
  dd 0xFFFFFFFF         ;Next free sector       (unknown)
  times 0x0E db 0       ;Reserved
  dw 0xAA55             ;Trail signature
  secalign 0x01,FSI_%1
  %endmacro
 fathead 0             ;0x0A
 secalign 0x04,Padding ;0x0C
 fathead 1             ;0x10
gen:
 %define fc 0
 %macro mkent 4-6
  ;%1, type
  ;%2, parent
  ;%3, name
  ;%4, attributes
  ;%5, file
  ;%6, size
  %assign file%[fc]_type   %1         ;Set FileN_type
  %assign file%[fc]_parent %2         ;Set FileN_parent
  %define file%[fc]_name   %3         ;Set FileN_name
  %assign file%[fc]_att    %4         ;Set FileN_att
  %if (%1 & 0x01 == 0x00)             ;Chk folder
  %assign file%[fc]_ct 0              ;Set FileN_ct (folder entries)
  %endif                              ;
  %if (%1 & 0x01 == 0x01)             ;Chk file
  %define file%[fc]_cfile %5          ;Set copy file
  file%[fc]_sz equ sz(file%[fc]_l)  ;Set size
  %endif                              ;
  %assign file%2_child%[file%2_ct] fc ;Set FileP_childN
  %assign file%2_ct file%2_ct+1       ;Inc FileP_ct
  %assign fc fc+1                     ;Adv to next entry
  %endmacro
 ;Note - This is where the folders/files are defined before being generated.
 ;Note - If you want to ignore all the details then just make a script to generate these with the proper values.
 ;Note - LFNs are not currently supported.
 ;Ent  Type, ParentFolder, DOSName,      Attr, CopyFile              ;mkent arguments
 mkent 0x00, 0,            'NagleF32   ',0x08                        ;0x00, Root
 mkent 0x00, 0,            'Folder0    ',0x10                        ;0x01, Folder0
 mkent 0x01, 1,            'TestFile   ',0x20, 'src/ExampleFile.txt' ;0x02, file
 ;Note - It is possible to rewrite this such that file sizes don't need to be passed in the script.
 ;Note - Maybe something for later. Not in the mood to rip apart functioning code right now.
fat:
 %macro fatnxt 0
  dd fatidx+1
  %assign fatidx fatidx+1
  %endmacro
 %macro fatend 0
  dd 0x0FFFFFFF
  %assign fatidx fatidx+1
  %endmacro
 %macro fat_gen 1.nolist
  dd 0x0FFFFFF0 ;Signature
  dd 0x0FFFFFFF ;Reserved
  %assign fi     0    ;File index
  %assign fatidx 0x02 ;Fat  index
  %rep fc
   %assign file%[fi]_fat fatidx        ;Set FAT idx
   %if (file%[fi]_type & 0x01 == 0x00) ;Folder
    %assign pi 0                     ;Set index counter
    %assign foldersz 0               ;Set folder size
    %rep file%[fi]_ct                ;Acm size
     ;Note - For potential LFN handling
     ;%assign chidx  file%[fi]_child%[pi] ;Get child idx
     ;%defstr chname  file%[chidx]_name   ;Get name token
     ;%strlen nameln chname               ;Get name length
     ;%assign nameln nameln-2             ;Without quotes
     ;%assign nametl (nameln/13)
     ;%assign foldersz foldersz+(nametl*0x20)
     ;%assign pi pi+1
     %assign foldersz foldersz+0x20
     %endrep
    %assign foldersz foldersz-1      ;Dec the size to only get overflows
    %assign extracls (foldersz/bpc)  ;Get the amount of extra clusters needed for this file
    %rep extracls                    ;Set clusters in FAT
    fatnxt                           ;Set clusters in FAT
    %endrep                          ;Set clusters in FAT
    %assign file%[fi]_cls extracls+1 ;Set the fent clusters
    %endif
   %if (file%[fi]_type & 0x01 == 0x01) ;File
    ;Note - Use of esoteric equ behavior to bypass the limitations of assign.
    ;Note - No idea if this is intended, or how exactly equ works, but it does work.
    filexc  equ file%[fi]_sz-1     ;Get the amount of extra clusters
    %rep filexc // bpc             ;Set clusters in FAT (must be // instead of / for some reason)
    fatnxt                         ;Set clusters in FAT
    %endrep                        ;Set clusters in FAT
    %assign file%[fi]_cls filexc+1 ;Set the fent clusters
    %endif
   fatend                              ;End FAT chain
   %assign fi fi+1                     ;Adv index
   %endrep
  secalign spf,FAT_%1
  %endmacro
 fat_gen 0
 fat_gen 1
files:
 %macro fent 4
  ;Note - Referencing the root cluster 0x02 seemed to break everything.
  ;Note - Not quite sure if or why I needed to do this or if it is part of the spec, but it works.
  %assign temp %3
  %if %3 == 0x02
   %assign temp 0x00
   %endif
  db %1             ;0x00 Name and extension
  db %2             ;0x0B Attributes
  db 0              ;0x0C NT reserved
  db 0              ;0x0D MS timestamp
  dw 0              ;0x0E Create time
  dw 0              ;0x10 Create date
  dw 0              ;0x12 Last access date
  dw temp  >> 0x10  ;0x14 High word of the first cluster
  dw 0              ;0x16 Write time
  dw 0              ;0x18 Write date
  dw temp  & 0xFFFF ;0x1A Low word of the first cluster
  dd %4             ;0x1C Byte count (0 for directories)
  %endmacro
 %macro mkfent 1
  %define chtype file%[%1]_type  ;Get type
  %define chtok  file%[%1]_name  ;Get name token
  %define chatt  file%[%1]_att   ;Get attributes
  %define cls    file%[%1]_fat   ;Get FAT
  %define size   0               ;Set size 0 for folder
  %if (chtype & 0x01 == 0x01)    ;File
  %define size   sz(file%[%1]_l) ;Get size
  %endif                         ;
  fent chtok,chatt,cls,size      ;Mke entry
  %endmacro
 %assign fi 0
 %rep fc
  %assign curtype file%[fi]_type      ;Get type
  %assign curpar  file%[fi]_parent    ;Get parent
  %define curname file%[fi]_name      ;Get name
  %assign curatt  file%[fi]_att       ;Get attributes
  %assign curfat  file%[fi]_fat       ;Get FAT index
  %assign curcls  file%[fi]_cls       ;Get clusters used
  %if (file%[fi]_type & 0x01 == 0x00) ;Folder
   %if (fi != 0)                               ;Chk root folder
   fent '.          ',0x10,curfat,0            ;Mke .
   fent '..         ',0x10,file%[curpar]_fat,0 ;Mke ..
   %endif                                      ;
   %assign pi 0                                ;Set index counter
   %rep file%[fi]_ct                           ;Mke child entries
    %assign chidx file%[fi]_child%[pi] ;Get child idx
    %assign chtype file%[chidx]_type   ;Get child type
    %define chtok  file%[chidx]_name   ;Get child name token
    %strlen nameln chtok               ;Get name length
    %if (nameln-2 > 13)                ;For potential LFN support
    %endif                             ;
    mkfent chidx                       ;Mke entry
    %assign pi pi+1                    ;Adv index
    %endrep
    secalign curcls, curname             ;Aln to cluster count
   %endif
  %if (file%[fi]_type & 0x01 == 0x01) ;File
   file%[fi]_l:
   incbin file%[fi]_cfile
   file%[fi]_l.end:
   secalign curcls, curname
   %endif
  %assign fi fi+1
  %endrep