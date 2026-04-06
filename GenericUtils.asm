;Todo - use local defines

%ifdef genutils
 %error GenericUtils.asm included twice!
 %endif
%define genutils
%defstr hexdef 0123456789ABCDEF
%macro hexprint 1-3.nolist
 %assign hex0 ((%1>>0x00) % 16)
 %assign hex1 ((%1>>0x04) % 16)
 %assign hex2 ((%1>>0x08) % 16)
 %assign hex3 ((%1>>0x0C) % 16)
 %assign hex4 ((%1>>0x10) % 16)
 %assign hex5 ((%1>>0x14) % 16)
 %assign hex6 ((%1>>0x18) % 16)
 %assign hex7 ((%1>>0x1C) % 16)
 %substr dig0 hexdef hex0+1
 %substr dig1 hexdef hex1+1
 %substr dig2 hexdef hex2+1
 %substr dig3 hexdef hex3+1
 %substr dig4 hexdef hex4+1
 %substr dig5 hexdef hex5+1
 %substr dig6 hexdef hex6+1
 %substr dig7 hexdef hex7+1
 %strcat final "0x" dig7 dig6 dig5 dig4 dig3 dig2 dig1 dig0
 %warning %2 final %3
 %endmacro

%define exp(x) x ;Force parameter expansion
%define roundd(x, y) x - (x % y)
%define roundu(x, y) x - (x % y) + (y * (x % y != 0))
%define sz(x) (exp(x).end - x)
%define sz(x,y) (exp(x).end - x)/y

%macro ml 1+
 %push mac_ml
 %defstr %$str %1    ;Cnv greedy parameter to string
 %strlen %$len %$str ;Get length
 %assign %$idx 1     ;Idx in full string
 %assign %$bse 1     ;Idx of part base
 %assign %$end 1     ;Idx of part end
 %rep %$len
  %substr %$chr %$str, %$idx, 3 ;Get next 3 chars
  %if %$chr == ' : '            ;Chk for separator
   %substr %$lne %$str, %$bse, %$end-1 ;Get part
   %deftok %$tok %$lne                 ;Cnv part string to token
   %$tok                               ;Out part
   %assign %$bse %$idx+2               ;Upd part base
   %assign %$end 0                     ;Rst part end
   %endif
  %assign %$idx %$idx+1         ;Adv strn idx
  %assign %$end %$end+1         ;Adv part end
  %endrep
 %substr %$lne %$str, %$bse, %$end-2 ;Get final part
 %deftok %$tok %$lne                 ;Cnv part string to token
 %$tok                               ;Out final part
 %pop mac_ml
 %endmacro

;XORShift randgen
%assign randseed __?POSIX_TIME?__
%macro getrand 0-1
 %assign temp     randseed
 %assign temp     temp<<21
 %assign randseed randseed^temp
 %assign temp     randseed
 %assign temp     temp>>35
 %assign randseed randseed^temp
 %assign temp     randseed
 %assign temp     temp<<4
 %assign randseed randseed^temp
 %assign rand randseed
 %if %0 == 1
 %assign %1 rand
 %endif
 %endmacro
%macro dbrand 0
 getrand
 db rand & 0xFF
 %endmacro
%macro dwrand 0
 getrand
 dw rand & 0xFFFF
 %endmacro
%macro ddrand 0
 getrand
 dd rand & 0xFFFFFF
 %endmacro
%macro dqrand 0
 getrand
 dq rand & 0xFFFFFFFFFFFFFFFF
 %endmacro

;Create and accumulate checksums
%macro chk_mke 2
 %assign chk_%1 %2
 %endmacro
%macro chk_acc 2
 %assign chk_%1 chk_%1 + %2
 %endmacro
%macro chk_fin 1
 %define %1 chk_%1
 %endmacro

;Generate CRC32 table
%define idx 0
%rep 0x100
 %assign char idx
 %assign val  0
 %rep 0x08
  %assign bit ((char^val) & 0x01)    ;Get bit
  %assign val val>>1         ;Shift val
  %if bit == 1
  %assign val val^0xEDB88320 ;If bit val^=poly
  %endif
  %assign char char>>1       ;Advance char
  %endrep
 %assign crc32tab%[idx] val
 %assign idx idx+1
 %endrep

;Create and accumulate crc32
%macro crc_mke 1
 %assign crc_%1 0xFFFFFFFF
 %endmacro
%macro crc_ab 2
 %assign char %2                   ;Set char
 %assign char   (char^crc_%1)&0xFF ;Xor with accumlator and get index
 %assign val    crc32tab%[char]    ;Get table index
 %assign crc_%1 crc_%1>>8          ;Shr acc
 %assign crc_%1 crc_%1^val         ;Xor to get finl
 %endmacro
%macro crc_aw 2
 %assign byte0 (%2>>0x00)&0xFF
 %assign byte1 (%2>>0x08)&0xFF
 crc_ab %1, byte0
 crc_ab %1, byte1
 %endmacro
%macro crc_ad 2
 %assign byte0 (%2>>0x00)&0xFF
 %assign byte1 (%2>>0x08)&0xFF
 %assign byte2 (%2>>0x10)&0xFF
 %assign byte3 (%2>>0x18)&0xFF
 crc_ab %1, byte0
 crc_ab %1, byte1
 crc_ab %1, byte2
 crc_ab %1, byte3
 %endmacro
%macro crc_aq 2
 %assign byte0 (%2>>0x00)&0xFF
 %assign byte1 (%2>>0x08)&0xFF
 %assign byte2 (%2>>0x10)&0xFF
 %assign byte3 (%2>>0x18)&0xFF
 %assign byte4 (%2>>0x20)&0xFF
 %assign byte5 (%2>>0x28)&0xFF
 %assign byte6 (%2>>0x30)&0xFF
 %assign byte7 (%2>>0x38)&0xFF
 crc_ab %1, byte0
 crc_ab %1, byte1
 crc_ab %1, byte2
 crc_ab %1, byte3
 crc_ab %1, byte4
 crc_ab %1, byte5
 crc_ab %1, byte6
 crc_ab %1, byte7
 %endmacro
%macro crc_fin 1
 %assign crc_%1 ~crc_%1
 %define %1 crc_%1
 %endmacro

;Two-pass pseudo-instructions
%assign ops 0
%macro crc_db 2
 %defstr optable%[ops] db %2
 crc_ab %1, %2
 %assign ops ops+1
 %endmacro
%macro crc_dw 2
 %defstr optable%[ops] dw %2
 crc_aw %1, %2
 %assign ops ops+1
 %endmacro
%macro crc_dd 2
 %defstr optable%[ops] dd %2
 crc_ad %1, %2
 %assign ops ops+1
 %endmacro
%macro crc_dq 2
 %defstr optable%[ops] dq %2
 crc_aq %1, %2
 %assign ops ops+1
 %endmacro
%macro p2op 1.nolist
 %defstr optable%[ops] %1
 %assign ops ops+1
 %endmacro
%macro pass_rst 0
 %assign ops 0
 %endmacro
%macro pass_fin 0.nolist
 %define temp 0
 %rep ops
  %deftok instr optable%[temp]
  ;%warning instr
  instr
  %assign temp temp+1
  %endrep
 %assign ops 0
 %endmacro

;Testing
;crc_mke  test
;crc_dd   test, 'Test'
;p2op     dd test
;crc_fin  test
;hexprint test
;finalize