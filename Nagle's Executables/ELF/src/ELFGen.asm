;Required labels/sections
 ;entry           ;Entry point, must be in code section
 ;code / code.end ;Section, must be page aligned
 ;data / data.end ;Section, must be page aligned

defs:
 imgbase:
 %define platform linux
 %include "../../ExeUtils.asm"
 [BITS 64]
 [DEFAULT REL]
 [ORG 0]
 %define rsrv roundu(end,0x1000)
 %ifndef rsrvsz
 %assign rsrvsz 0
 %define sectidx(x) (x-sects)/0x40
 %endif
imports:
 %assign libs  0
 %assign funcs 0
 %macro addlib 1
  %ifndef libinc_%1         ;Chk library already included
  %define libinc_%1         ;Ifn define it
  %defstr lib%[libs]_nme %1 ;Def library name
  %assign libs libs+1   ;Adv library index
  %endif
  %endmacro
 %macro import 1-3
  %ifndef fninc_%1              ;Chk function already included
  %define fninc_%1              ;Ifn define it
  %defstr fn%[funcs]_str %1     ;Def symbol name
  %assign fn%[funcs]_typ 0x00   ;Def symbol type
  %assign funcs funcs+1         ;Adv symbol index
  %ifidn %3, forced
   %define %1_used
   %endif
  %endif
  %endmacro
 %macro export 2
  %defstr fn%[funcs]_str %1
  %assign fn%[funcs]_typ 0x01
  %define fn%[funcs]_val %2
  %assign funcs funcs+1
  %endmacro
%macro prog_head 0
 hdr:
 elfhead:
  dd 0x464C457F         ;File identifier (0x7F, 'ELF')
  db 0x02               ;Executable format (0x01=32bit, 0x02=64bit)
  db 0x01               ;Endianness (0x01=little, 0x02=big)
  db 0x01               ;ELF Version
  db 0x00               ;Target ABI (0x00=System V)
  db 0x00               ;ABI version
  times 7 db 0          ;Unused/reserved
  dw 0x0003             ;Object type (0x0003=Dynamic)
  dw 0x003E             ;Target machine (0x003E=AMDx86-64)
  dd 0x00000001         ;ELF Version
  dq entry              ;Program entry point
  dq segments           ;Program header table
  dq sects              ;Section header table
  dd 0                  ;Flags
  dw 0x0040             ;Header size
  dw 0x0038             ;Program header entry size
  dw sz(segments)/0x38  ;Program header entry count
  dw 0x40               ;Section header entry size
  dw sz(sects)/0x40     ;Section header entry count
  dw sectidx(sect_str)  ;Section header string table index
 segments:
  %macro progent 6
   dd %1 ;0x00 Type
   dd %2 ;0x04 Flags
   dq %3 ;0x08 File offset
   dq %3 ;0x10 Virtual address
   dq %3 ;0x18 Physical address
   dq %4 ;0x20 Size in file
   dq %5 ;0x28 Size in memory
   dq %6 ;0x30 Alignment
   %endmacro
  ;       Type, Flag, FileAddr, FileSz,       MemSz,                   Alignment
  progent 0x06, 0x04, segments, sz(segments), sz(segments),            0x08   ;Self descriptor
  progent 0x01, 0x06, hdr,      sz(hdr),      sz(hdr),                 0x1000 ;Headers
  progent 0x01, 0x03, code,     sz(code),     roundu(sz(code),0x1000), 0x1000 ;Code
  progent 0x01, 0x06, data,     sz(data),     roundu(sz(data),0x1000), 0x1000 ;Data
  progent 0x01, 0x06, tabs,     sz(tabs),     roundu(sz(tabs),0x1000), 0x1000 ;Data
  %if rsrvsz != 0
  progent 0x01, 0x06, roundu(end,0x1000), 0, roundu(rsrvsz,0x1000),   0x1000  ;BSS
  %endif
  progent 0x02, 0x06, dyna,     sz(dyna),     sz(dyna),                0x08   ;Dynamic table
  progent 0x03, 0x04, interp,   sz(interp),   sz(interp),              0x01   ;Interp string
  segments.end:
 interp:
  db '/lib64/ld-linux-x86-64.so.2',0
  interp.end:
 align 0x1000, db 0
 hdr.end:
 %endmacro
%macro prog_end 0
 %macro fn_used 1
  %deftok fntok %1_str
  %if %isdef(%[fntok]_used) || %1_typ == 0x01
  %endmacro
 tabs:
 dyna:
  %assign idx 0
  %rep libs                      ;Libraries
  dq 0x01,libstr%[idx]-dynstr    ;Library string index
  %assign idx idx+1              ;Inc idx
  %endrep                        ;Libraries
  dq 0x05,dynstr                 ;Dynamic    string table
  dq 0x06,dynsym                 ;Dynamic    symbol table
  dq 0x07,reloc                  ;Relocation table
  dq 0x08,sz(reloc)              ;Relocation table size
  dq 0x09,0x18                   ;Relocation table entry size
  dq 0x0A,sz(dynstr)             ;Dynamic    string table size
  dq 0x0B,0x18                   ;Dynamic    symbol table entry size
  dq 0x000000006ffffef5,gnu_hash ;GNU Hash
  dq 0,0
  dyna.end:
 dynsym:
  ;Note - The three null entries are to fix a linker edgecase bug that I simply cannot figure out.
  ;Note - If the first export is either the 1st or 2nd symbol table entry the linker won't find it.
  ;Note - Probably a skill issue on my part, but I couldn't figure out anything else to get it to work.
  times 0x03 dq 0 ;Null entry
  times 0x03 dq 0 ;Null entry
  times 0x03 dq 0 ;Null entry
  %assign idx 0
  %rep funcs
  fn_used fn%[idx]
  %if fn%[idx]_typ == 0x00
   funsym%[idx]:
   dd fnstr%[idx]-dynstr ;0x00 st_name
   db 0x12               ;0x04 st_info, Global function
   db 0x00               ;0x05 st_other
   dw 0                  ;0x06 st_shndx
   dq 0                  ;0x08 st_value
   dq 0                  ;0x10 st_size
   %endif
  %endif
  %if fn%[idx]_typ == 0x01
   dd fnstr%[idx]-dynstr ;0x00 st_name
   db 0x10               ;0x04 st_info  global, no type
   db 0x00               ;0x05 st_other
   dw 0x01               ;0x06 st_shndx code
   dq fn%[idx]_val       ;0x08 st_value
   dq 0x08               ;0x10 st_size
   %endif
  %assign idx idx+1
  %endrep
  dynsym.end:
  align 0x08, db 0
 reloc:
  dq 0,0,0 ;Null entry
  %assign idx 0
  %rep funcs
  fn_used fn%[idx]
  %if fn%[idx]_typ == 0x00
   dq %tok(fn%[idx]_str)                     ;0x00 Relocation address
   dd 0x06                                   ;0x08 Type, symbol
   dd (((funsym%[idx]-$$)-(dynsym-$$))/0x18) ;0x0C Symbol index
   dq 0x00                                   ;0x10 Addend
   %endif
  %endif
  %assign idx idx+1
  %endrep
  reloc.end:
  align 0x08, db 0
 gnu_hash:
  %macro gnuhash 1.nolist
   %assign hashvalue  5381
   %strlen hashstrlen %1
   %assign hashstridx 1
   %rep hashstrlen
    %substr hashchar %1 hashstridx hashstridx
    %assign hashvalue (hashvalue<<5)+hashvalue+hashchar
    %assign hashstridx hashstridx+1
    %endrep
   %assign hashvalue hashvalue & 0xFFFFFFFE
   %if fdi == funcs-1
    %assign hashvalue hashvalue | 1
    %endif
   dd hashvalue
   %endmacro
  dd 0x00000001         ;Buckets
  dd 0x00000003         ;Symbol offset (skip null entry)
  dd 0x00000001         ;Bloom size
  dd 0x00000000         ;Bloom shift
  dq 0xFFFFFFFFFFFFFFFF ;Bloom  0 (always pass)
  dd 0x00000003         ;Bucket 0 starts at symtab 1
  %assign fdi 0
  %rep funcs
   fn_used fn%[fdi]
   gnuhash fn%[fdi]_str
   %endif
   %assign fdi fdi+1
   %endrep
  ;Note - Potential edgecase fix where the final import isn't used causing the chain to never end.
  ;Note - Testing this case didn't cause any issues, but it's probably better here than not.
  ;Note - Could be fixed fairly easily but I don't care much.
  dd -1
  gnu_hash.end:
  align 0x08, db 0
 dynstr:
  %assign idx 0
  %rep libs
   libstr%[idx] db lib%[idx]_nme, 0
   %assign idx idx+1
   %endrep
  %assign idx 0
  %rep funcs
   fn_used fn%[idx]
   fnstr%[idx] db fn%[idx]_str,0
   %endif
   %assign idx idx+1
   %endrep
  dynstr.end:
  align 0x08, db 0
 functab:
  %assign idx 0
  %rep funcs
  fn_used fn%[idx]
  %tok(fn%[idx]_str) dq 0
  %endif
  %assign idx idx+1
  %endrep
 tabs.end:
 end:
 errs:
  %if (code-$$) % 0x1000 != 0
   %error "Code section not page aligned"
   %endif
  %if (data-$$) % 0x1000 != 0
   %error "Data section not page aligned"
   %endif
 sections:
  %assign sci 0
  %macro sectent 10
   %defstr sect%[sci]_str %1
   dd sect%[sci]_sti-secstr     ;Name
   dd %2                        ;Type
   dq %3                        ;Flags
   dq %4                        ;Virtual address
   dq %5                        ;File offset
   dq %6                        ;Size
   dd %7                        ;Link0
   dd %8                        ;Link1
   dq %9                        ;Alignment
   dq %10                       ;Entry size
   %assign sci sci+1
   %endmacro
  sects:
   sect_null times 0x08 dq 0
   ;                   Name,     Type, Flag, VAddr,  FAddr,  Size,       Lnk0,                 Lnk1,            Algn,   Entsz
   sect_code   sectent .code,    0x01, 0x02, code,   code,   sz(code),   sectidx(sect_null),   sectidx(sect_null),   0x1000, 0x01
   sect_data   sectent .data,    0x01, 0x02, data,   data,   sz(data),   sectidx(sect_null),   sectidx(sect_null),   0x1000, 0x01
   sect_dynsym sectent .dynsym,  0x0B, 0x02, dynsym, dynsym, sz(dynsym), sectidx(sect_dynstr), sectidx(sect_dynsym), 0x08,   0x18
   sect_dynstr sectent .dynstr,  0x03, 0x02, dynstr, dynstr, sz(dynstr), sectidx(sect_null),   sectidx(sect_null),   0x01,   0x00
   sect_str    sectent .strtab,  0x03, 0x00, 0x00,   secstr, sz(secstr), sectidx(sect_null),   sectidx(sect_null),   0x01,   0x00
   sects.end:
  secstr:
   db 0
   %assign idx 0
   %rep sci
   sect%[idx]_sti: db sect%[idx]_str,0
   %assign idx idx+1
   %endrep
   secstr.end:
 %endmacro