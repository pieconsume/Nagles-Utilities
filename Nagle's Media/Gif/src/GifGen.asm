%include "../MediaUtils.asm"

%assign wdt   0x08  ;Width
%assign hgt   0x08  ;Height
%assign clr   0x04  ;Bits per index
%assign clrb  clr-1 ;Flag value
hexprint wdt, Generated gif width :
hexprint hgt, Generated gif height:
%define clr_0  0x00000000 ;Transparency index
%define clr_1  0x00000000 ;Black
%define clr_2  0x00FFFFFF ;White
%define clr_3  0x000000FF ;Red
%define clr_4  0x0000FF00 ;Green
%define clr_5  0x00FF0000 ;Blue
%define clr_6  0x0000FFFF ;Yellow
%define clr_7  0x00FF00FF ;Purple
%define clr_8  0x00FF00FF ;Purple
%define clr_9  0x00FF00FF ;Purple
%define clr_10 0x00FF00FF ;Purple
%define clr_11 0x00FF00FF ;Purple
%define clr_12 0x00FF00FF ;Purple
%define clr_13 0x00FF00FF ;Purple
%define clr_14 0x00FF00FF ;Purple
%define clr_15 0x00FF00FF ;Purple

header:
 db 'GIF89a'  ;0x00 Identifer
 dw wdt       ;0x06 Width
 dw hgt       ;0x08 Height
 db 0xF0|clrb ;0x0A Flags
 db 0x00      ;0x0B Background index
 db 0x00      ;0x0C Pixel ratio
gct:
 %assign idx 0
 %rep 1<<clr
  db (clr_%[idx] >> 0x00) & 0xFF
  db (clr_%[idx] >> 0x08) & 0xFF
  db (clr_%[idx] >> 0x10) & 0xFF
  %assign idx idx+1
  %endrep
gce:
 db 0x21   ;0x00 Extension identifier
 db 0xF9   ;0x01 Graphic control identifier
 db 0x04   ;0x02 GCE size
 db 0x00   ;0x03 Transparent background color
 dw 0x0001 ;0x04 Animation delay in ms
 db 0x00   ;0x06 Color number of transparent pixel
 db 0x00   ;0x07 GCE end
imd:
 db 0x2C       ;0x45 Identifer
 dd 0x00000000 ;0x46 Top left corner
 dw wdt        ;0x4A Width
 dw hgt        ;0x4C Height
 db 0x00       ;0x4E Local color table bit
img:
 %assign pxi 0
 %macro px 1
  %define px%[pxi] %1
  %assign pxi pxi+1
  %endmacro
 pxgen:
  %rep wdt*hgt*2
  getrand
  px rand & 0x07
  %endrep
 lzwgen:
  %assign bpp clr    ;Bits per pixel
  %assign bpe clr+1  ;Bits per entry
  %assign byt 0      ;Byte
  %assign byc 0      ;Byte position
  %assign btt 0      ;Byte total
  %assign idx 0      ;Pixel index
  ;%define nocomp
  %macro outbit 1.nolist
   %assign byt (byt | (%1<<byc)) ;Set bit in byte
   %assign byc byc+1             ;Inc byte bit count
   %if byc == 8
   db byt
   ;hexprint byt, Byte:
   %assign byt 0     ;Rst byte
   %assign byc 0     ;Rst byte bit count
   %assign btt btt+1 ;Inc byte total
   %endif
   %endmacro
  %macro outpix 1.nolist
   %assign val %1
   ;hexprint val, Pixel:
   %rep bpe
    %assign bit (val &  0x01)      ;Get lowest bit
    outbit  bit
    %assign val (val >> 0x01)      ;Get next bit
    %endrep
   %assign dct dct+1
   %endmacro
  %macro outblk 0
   %push block
   db %$data.end-%$data ;Amount of data
   %$data:
   %ifdef nocomp
    %assign dct (1<<bpp) ;Dictionary index
    %assign rst dct      ;Reset value
    %assign bnd dct+1    ;Block end value
    outpix rst
    %assign dct dct+1
    %rep 0x10000
    outpix px%[idx]       ;Out pixel
    %assign idx idx+1     ;Inc pixel idx
    %if btt == 0x20       ;Chk the block has finished
     %assign btt 0
     %exitrep
     %endif
    %if dct == (rst<<1)-1 ;Chk dictionary needs reset
     %assign dct (1<<bpp)
     outpix rst
     %endif
    %if idx == pxi        ;Chk all pixels have been output
     %exitrep
     %endif
    %if btt == 0x20       ;Chk the block has finished
     %assign btt 0
     %exitrep
     %endif
    %endrep
   %else
    %if idx == 0
     %assign dct (1<<bpp) ;Dictionary index
     %assign rst dct      ;Reset value
     %assign bnd dct+1    ;Block end value
     outpix rst
     %assign dct dct+1
     %endif
    %rep 0x10000
     %if idx == pxi-1          ;Chk this is the final pixel
      outpix px%[idx]
      %assign idx idx+1
      %exitrep
      %endif
     %assign px0 px%[idx]      ;Get search pixel 0
     %assign tmp idx+1         ;Get next pixel
     %assign px1 px%[tmp]      ;Get next pixel
     %assign tbl%[dct]_fst px0 ;Set first pixel entry
     %assign tbl%[dct]_val px0 ;Set initial code of entry
     %assign ix0 bnd+1         ;Set search index
     %assign ix1 ix0+1         ;Set search index+1
     %rep dct-bnd-1            ;Sch from the first table index to the last
      ;%warning Index: [dct], Comp1: [ix0], Cmp2: [ix1], Pixel0: [px0], Pixel1: [px1], Val0: [tbl%[ix0]_val], Val1: [tbl%[ix1]_fst]
      %assign cm0 tbl%[ix0]_val ;Chk tbl[ix0]_val is the code/pixel being searched for
      %assign cm1 tbl%[ix1]_fst ;Chk tbl[ix1]_fst is the next pixel
      %if (px0 == cm0) && (px1 == cm1)
       %assign px0 ix0           ;Set px0 to backref
       %assign tbl%[dct]_val ix0 ;Set val to backref
       ;%warning Match found, set value of dct to tbl%[dct]_val
       %assign idx idx+1    ;Adv pixel index
       %if idx == pxi-1     ;Chk this is the final pixel
        %exitrep            ;Ext loop if so
        %endif
       %assign tmp idx+1    ;Get next pixel index
       %assign px1 px%[tmp] ;Get next pixel index
       %endif
      %assign ix0 ix0+1    ;Adv dictionary search indexes
      %assign ix1 ix1+1    ;Adv dictionary search indexes
      %endrep
     outpix px0            ;Out pixel
     %assign idx idx+1     ;Adv idx
     %if btt > 0xFD       ;Chk the block has finished
      %assign btt 0
      %exitrep
      %endif
     %if idx == pxi        ;Chk all pixels have been output
      %exitrep
      %endif
     %if dct == 0xFFF
      %assign dcx 0
      %rep dct-bnd
       %undef tbl%[dcx]_fst
       %undef tbl%[dcx]_val
       %assign dcx dcx+1
       %endrep
      outpix rst
      %assign dct (1<<bpp)
      %assign dct dct+2
      %warning gwog
      %assign bpe bpp+1
      %endif
     %if dct == (1<<bpe)+1
      ;%warning dct bpe
      %assign bpe bpe+1
      %endif
     %if btt > 0xFD       ;Chk the block has finished
      %assign btt 0
      %exitrep
      %endif
     %endrep
   %if idx == pxi
    outpix bnd
    %endif
   %endif
   %$data.end:
   %pop block
   %endmacro
  data:
  db bpp ;Starting bits per code
  %rep 0x10000
   outblk
   %if idx == pxi
   %exitrep
   %endif
   %endrep
  db 0x00
  db 0x3B
  data.end: