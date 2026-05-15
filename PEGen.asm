;Required labels
 ;entry           ;Entry point, must be in code section
 ;code / code.end ;Section, must be page aligned
 ;data / data.end ;Section, must be page aligned

defs:
 img:
 %define platform win64
 %include "../../ExeUtils.asm"
 [BITS 64]
 [DEFAULT REL]
 [ORG 0]
 [WARNING -label-redef-late]
 %ifdef dll
  %assign pe_type 0x2000
 %else
  %assign pe_type 0x0002
  %endif
imports:
 %assign libs 0
 %assign exps 0
 %macro addlib 1
  %ifndef libinc_%1         ;Chk library already included
  %define libinc_%1         ;Ifn define it
  %assign libidx_%1 libs    ;Set the index of the library
  %defstr lib%[libs]_nme %1 ;Def library name
  %assign lib%[libs]_fns 0  ;Def library function count
  %assign libs libs+1       ;Adv library index
  %endif
  %endmacro
 %macro import 2-3
  %ifndef fninc_%1                      ;Chk function already included
  %define fninc_%1                      ;Ifn define it
  %assign lbi libidx_%2                 ;Get library index
  %assign fni lib%[lbi]_fns             ;Get function index
  %defstr lib%[lbi]_fn%[fni]_nme %1     ;Def symbol name
  %define lib%[lbi]_fn%[fni]_tok %1     ;Def symbol name
  %assign lib%[lbi]_fns lib%[lbi]_fns+1 ;Inc function count
  %ifidn %3, forced
   %define %1_used
   %endif
  %endif
  %endmacro
 %macro export 2
  %defstr exp%[exps]_nme %1
  %define exp%[exps]_val %2
  %assign exps exps+1
  %endmacro
%macro prog_head 0
 %ifndef imgtop
  %define imgsz end
 %else
  %define imgsz imgtop
  %endif
 stub:
  dw 0x5A4D             ;Magic "MZ"
  times 0x3A db 0       ;Unused values
  dd pe                 ;PE Offset
 pe:
  dw 0x4550             ;Magic
  dw 0                  ;What?
  dw 0x8664             ;Machine
  dw sz(sections,0x20)  ;Sections
  dd 0                  ;Timestamp
  dq 0                  ;Symbol table pointer
  dw sz(optional)       ;Size of optional header
  dw pe_type            ;Characteristics
 optional:
  db 0x0B,0x02,0x0E,0x1D ;Magic, link versions
  dd sz(code)            ;Size of code
  dd sz(data)            ;Size of data
  dd 0                   ;Size of reserved space
  dd entry               ;Entry point
  dd code                ;Base of code
  dq 0x0000000000000000  ;Base of image
  dd 0x1000,0x1000       ;Section alignment, file alignment
  times 0x08 dw 0        ;Versions
  dd imgsz               ;Size of image
  dd 0x1000              ;Size of headers
  dd 0                   ;Checksum
  dw 0                   ;Subsystem
  dw 0x8140              ;DLL characteristics
  dq 0x10000,0x1000      ;Stack reserve/commit
  dq 0x10000,0x1000      ;Heap reserve/commit
  dd 0                   ;Loader flags
  dd sz(rva,0x08)        ;RVA count
 rva:
  %macro rvaent 1
   dd %1
   dd sz(%1)
   %endmacro
  rvaent table_expdir ;Export directory
  rvaent table_impdir ;Import directory
  rvaent null         ;Resource
  rvaent null         ;Exception
  rvaent null         ;Certificate
  rvaent null         ;Base relocation
  ;rvaent table_debug  ;Debug
  rvaent null         ;Debug
  rvaent null         ;Architecture
  rvaent null         ;Global PTR
  rvaent null         ;TLS
  rvaent null         ;Load config
  rvaent null         ;Bound import
  rvaent table_impadd ;Import address
  rvaent null         ;Delay import
  rvaent null         ;CLR runtime
  rvaent null         ;Reserved
  rva.end:
  optional.end:
 sections:
  %macro sectent 5
   dq %1                    ;0x00 Name
   dd %4                    ;0x08 Virtual size
   dd %2                    ;0x0C Virtual address
   dd %3                    ;0x10 Size of raw data
   dd %2                    ;0x14 Pointer to raw data
   dd 0                     ;0x18 What?
   dd 0                     ;0x1C What?
   dd 0                     ;0x20 What?
   dd %5                    ;0x24 Characteristics
   %endmacro
  ;Relevant flags
   ;0x10000000 Share
   ;0x20000000 Exec
   ;0x40000000 Read
   ;0x80000000 Write
  ;       Name,    Addr, FileSize, VirtSize                 Flags
  sectent ".text", code, sz(code), roundu(sz(code),0x1000), 0x20000000
  sectent ".data", data, sz(data), roundu(sz(data),0x1000), 0xC0000000
  sectent ".tabs", tabs, sz(tabs), roundu(sz(tabs),0x1000), 0xC0000000
  %assign idx 0
  %ifdef secidx
   %rep secidx
   %strcat name ".", sec%[idx].name
   sectent name, sec%[idx].base, 0, sec%[idx].size,   0xC0000000
   %assign idx idx+1
   %endrep
   %endif
  sections.end:
  pe.end:
  times 0x1000-(pe.end-stub) db 0
  %endmacro
%macro prog_end 0
 tabs:
 align 0x08, db 0
 edata:
  table_expdir:
   dd 0x00000000   ;0x00 Reserved
   dd 0x00000000   ;0x04 Timestamp
   dw 0x0000       ;0x06 Version major
   dw 0x0000       ;0x08 Version minor
   dd dllname      ;0x0C Name
   dd 0x00000001   ;0x10 Ordinal base
   dd exps         ;0x14 Export address table entries
   dd exps         ;0x18 Name pointer/ordinal table entries
   dd table_expadd ;0x1C Export address table
   dd table_expnpt ;0x20 Export nameptr table
   dd table_expord ;0x24 Export ordinal table
   table_expdir.end:
   align 0x08, db 0
  table_expadd: ;Export address table
   %assign idx 0
   %rep exps
   dd exp%[idx]_val ;Exported value RVA
   dd 0             ;Forwarder
   %assign idx idx+1
   %endrep
   table_expadd.end:
   align 0x08, db 0
  table_expnpt: ;Export nameptr table
   %assign idx 0
   %rep exps
   dd exp%[idx]_str
   %assign idx idx+1
   %endrep
   table_expnpt.end:
   align 0x08, db 0
  table_expord: ;Export ordinal table
   %assign idx 0
   %rep exps
   dw idx
   %assign idx idx+1
   %endrep
   table_expord.end:
   align 0x08, db 0
  table_expnme: ;Export name    table
   dllname db "PETest.dll", 0
   %assign idx 0
   %rep exps
   exp%[idx]_str db exp%[idx]_nme, 0
   %assign idx idx+1
   %endrep
   table_expnme.end:
   align 0x08, db 0
  edata.end:
 idata:
  %macro fn_used 1
   %if %isdef(%[%1_tok]_used)
   %endmacro
  table_impdir: ;Import directory
   %assign idx 0
   %rep libs
   dd lib%[idx]_lku ;0x00 Lookup table
   dd 0x00000000    ;0x04 Timestamp
   dd 0x00000000    ;0x08 Forwarder chain (unused)
   dd lib%[idx]_str ;0x0C Name
   dd lib%[idx]_adr ;0x10 Address table
   %assign idx idx+1
   %endrep
   times 0x14 db 0  ;Null entry
   table_impdir.end:
   align 0x08,db 0
  table_impadd: ;Import
   %assign idx 0
   %rep libs
    lib%[idx]_adr:
    %assign fni 0
    %rep lib%[idx]_fns
    fn_used lib%[idx]_fn%[fni]
    lib%[idx]_fn%[fni]_tok: dq lib%[idx]_fn%[fni]_str
    %endif
    %assign fni fni+1
    %endrep
    dq 0              ;End table
    %assign idx idx+1
    %endrep
   table_impadd.end:
   align 0x08,db 0
  table_implku: ;Import lookup
   %assign idx 0
   %rep libs
    lib%[idx]_lku:
    %assign fni 0
    %rep lib%[idx]_fns
    fn_used lib%[idx]_fn%[fni]
    dq lib%[idx]_fn%[fni]_str
    %endif
    %assign fni fni+1
    %endrep
    dq 0              ;End table
    %assign idx idx+1
    %endrep
   table_implku.end:
   align 0x08,db 0
  table_impstr: ;Import strings
   %assign idx 0
   %rep libs
   lib%[idx]_str db lib%[idx]_nme, 0
   %assign idx idx+1
   %endrep
   table_impstr.end:
   align 0x08,db 0
  table_hintnm: ;Import name hints
   %assign idx 0
   %rep libs
   %assign fni 0
   %rep lib%[idx]_fns
   fn_used lib%[idx]_fn%[fni]
   lib%[idx]_fn%[fni]_str db 0,0,lib%[idx]_fn%[fni]_nme,0
   %endif
   %assign fni fni+1
   %endrep
   %assign idx idx+1
   %endrep
   align 0x08,db 0
  idata.end:
 debug: ;Note - Unused test code to enable CET
  ;table_debug:
  ; dd 0x00000000     ;0x00 Reserved
  ; dd 0x00000000     ;0x04 Time and date
  ; dw 0x0000         ;0x08 Major version
  ; dw 0x0000         ;0x0A Minor version
  ; dd 0x00000014     ;0x0C Type, IMAGE_DEBUG_TYPE_EX_DLLCHARACTERISTICS
  ; dd sz(debug_data) ;0x10 Data size
  ; dd 0x00000000     ;0x14 Address
  ; dd debug_data     ;0x18 File offset
  ; table_debug.end:
  ;debug_data:
  ; dq 0x0040
  ; debug_data.end:
 tabs.end:
 end:
 %endmacro