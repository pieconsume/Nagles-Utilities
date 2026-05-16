defs:
 %include "../../CompatGen.asm"
imports:
 util_compat_stdc
 util_compat_cmdl
 util_compat_exc
 util_compat_dbg
 util_compat_section bss, 0x10000
 %define dbg_allfuncs
 %ifidn platform, win64
  addlib msvcr120.dll
  %endif
 %ifidn platform, linux
  addlib libc.so.6
  %endif
 ;C imports
  import printf,  msvcr120.dll
  import exit,    msvcr120.dll
  import fopen,   msvcr120.dll
  import fread,   msvcr120.dll
  import fprintf, msvcr120.dll
  import feof,    msvcr120.dll
  import ferror,  msvcr120.dll
  import fclose,  msvcr120.dll
  import strcspn, msvcr120.dll
  import strpbrk, msvcr120.dll
  import strcmp,  msvcr120.dll
  import strncmp, msvcr120.dll
  import strlen,  msvcr120.dll
  import strtol,  msvcr120.dll
 prog_head
code:
 fn entry,      prog, 0x10, line
  %push ctx_main
  exc_handler on_exc
  call getargs
  ml mov p1q,[infile]  : dbg_printf "Infile:  [0x%016llX]",10,0
  ml mov p1q,[outfile] : dbg_printf "Outfile: [0x%016llX]",10,0
  ml mov p1q,[count ]  : dbg_printf "Count:   [0x%016llX]",10,0
  ml mov p1q,[perline] : dbg_printf "Line:    [0x%016llX]",10,0
  ml mov p1q,[nasm]    : dbg_printf "Nasm:    [0x%016llX]",10,0
  %$readloop:
   mov p0q,[infile]  ;Set infile
   ccl [feof]        ;Get end of file flag
   test r0d,r0d      ;Chk eof
   jnz %$done        ;Ext if not zero
   lea  p0q,[bss]    ;Set out buffer
   mov  p1d,0x01     ;Set size
   mov  p2d,0x10000   ;Set count
   mov  p3q,[infile] ;Set file
   ccl  [fread]      ;Run
   test r0d,r0d      ;Chk 0
   mov  s0d,r0d      ;Sve return count
   cmp  r0d,0x10000  ;Chk r0d
   setl s1b          ;Set flag everything has been read
   mov  p0q,[infile] ;Set file
   ccl  [ferror]     ;Get error
   test r0d,r0d      ;Chk error
   jnz  %$readerr    ;Err if set
   test s0d,s0d      ;Chk byte count
   jz %$done         ;Ext if zero.
   call outbuf       ;Out read data
   test s1b,s1b      ;Chk buffer fully read
   jz %$readloop     ;Rpt if not
  dbg_printf "Finished",10,0
  ccl  [exit]
  %$readerr:
   dbg_printf "some error",10,0
   ccl [exit]
  %$done:
   dbg_printf "Finished",10,0
   ccl [exit]
  %pop ctx_main
 fn getargs,    abis, 0x10, line
  mov s0q,[argv] ;Get arg
  mov s5d,[argc] ;Get argc
  add s0q,0x08   ;Skp file name
  dec s5d        ;Skp file name
  xor p0d,p0d    ;Clr errno
  seterrno       ;Clr errno
  arg_parse:
   %assign argidx 0
   %define rfil 0x01
   %define wfil 0x02
   %define long 0x03
   %define bool 0x04
   %macro parsearg 3-*
    ;%1,  output address
    ;%2,  input type
    %define %%output %1
    %define %%type   %2
    %rep %0-2
    %define argdef%[argidx] %3 ;Def name
    %strlen arglen %3          ;Def length
    lea  s1q,[argstr%[argidx]] ;Set arg string
    lea  s2q,%%output          ;Set output address
    mov  s3d,%%type            ;Set parse type
    mov  s4d,arglen            ;Set arglen
    call parse_argv            ;Prs arg
    test r0d,r0d               ;Chk return value
    jz arg_next                ;Skp if found
    %assign argidx argidx+1
    %rotate 1
    %endrep
    %endmacro
   parsearg [infile],  rfil,"-i","-input" ,"-infile"
   parsearg [outfile], wfil,"-o","-output","-outfile"
   parsearg [count],   long,"-c","-count"
   parsearg [perline], long,"-l","-line"
   parsearg [nasm],    bool,"-n","-nasm"
   mov p1q,[s0q]
   dbg_printf "Unrecognized arg: %s",10,0
   arg_next:
    add s0q,0x08
    dec s5d
    jnz arg_parse
   fnr abis
  arg_none:
   dbg_printf "Nagle's Hexdump Utility (unreleased)",10,0
   dbg_printf "Usage: ",10,0
   dbg_printf " ngdg -i,infile  [Required] Set infile.",10,0
   dbg_printf " ngdg -o,outfile [Optional] Set outfile.",10,0
   dbg_printf " ngdg -c,count   [Optional] Set byte count.",10,0
   dbg_printf " ngdg -l,count   [Optional] Set bytes per line.",10,0
   dbg_printf " ngdg -n,true    [Optional] Enable nasm repatch mode.",10,0
   fnr abis
 fn outbuf,     abic, 0x10, line
  %assign fpf_idx 0
  %macro auto_fprintf 2+
   %define fpf%[fpf_idx] %2
   mov p0q,%1
   lea p1q,[str_fpf%[fpf_idx]]
   ccl [fprintf]
   %assign fpf_idx fpf_idx+1
   %endmacro
  %push ctx_outbuf
  ;s0d, byte count
  lea s1q,[bss]
  mov s4d,[perline]
  %$outer:
   mov s5d,s4d
   %$inner:
    movzx p2d,byte[s1q]
    auto_fprintf [outfile],"%02llX",0
    dec s0d
    jz %$done
    inc s1q
    dec s5d
    jnz %$inner
   auto_fprintf [outfile],"",10,0
   jmp %$outer
  %$done:
  %pop ctx_outbuf
  fnr abic
 fn parse_argv, abis, 0x10, line
  ;s0q, argv ptr
  ;s1q, compare string
  ;s2q, output  address
  ;s3d, output  type
  ;s4d, arglen
  mov p0q,[s0q]              ;Get inp string
  lea p1q,[str_comma]        ;Get comma string
  ccl [strcspn]              ;Get comma position in string
  cmp r0d,s4d                ;Cmp with arglen
  jne argv_nomatch           ;Skp if not equal
  mov p0q,[s0q]              ;Get inp string
  mov p1q,s1q                ;Get cmp string
  mov p2d,s4d                ;Get cmp string length
  ccl [strncmp]              ;Cmp strings
  test r0d,r0d               ;Chk same
  jnz argv_nomatch           ;Skp if not same
  mov p0q,[s0q]              ;Get inp string
  lea p1q,[str_comma]        ;Get comma string
  ccl [strpbrk]              ;Get pointer to comma
  inc r0q                    ;Inc past comma
  mov p0q,r0q                ;Set p0q for passing
  lea p1q,[fopen_rd]         ;Get read  file flags
  lea p2q,[fopen_wr]         ;Get write file flags
  cmp s3d,wfil               ;Chk filetype
  cmove p1q,p2q              ;Set flags
  cmpje s3d,rfil, parse_file ;Chk file
  cmpje s3d,wfil, parse_file ;Chk file
  cmpje s3d,long, parse_long ;Chk long
  cmpje s3d,bool, parse_bool ;Chk bool
  argv_nomatch:
  mov r0d,0x01 ;Set ret value
  fnr abis
 fn parse_file, leaf, 0x10, line
  ;p0q, arg value pointer
  ;p1q, flag string
  ccl  [fopen]      ;Run
  test r0d,r0d      ;Chk error
  jz   parse_errh   ;Err
  mov  [s2q],r0q    ;Set arg value
  xor r0d,r0d       ;Set ret value
  fnr abis
 fn parse_long, leaf, 0x10, line
  ;p0q, arg value pointer
  xor  p1d,p1d  ;Clr endptr
  xor  p2d,p2d  ;Clr base
  ccl  [strtol] ;Get val
  test r0d,r0d  ;Chk error / 0
  jz parse_errh ;Err
  mov [s2q],r0q ;Set return value
  xor r0d,r0d
  fnr abis
 fn parse_bool, leaf, 0x10, line
  %push ctx_parse_bool
  mov s1q,p0q         ;Sve arg value in s1q
  lea p1q,[str_true]  ;Get true str
  ccl [strcmp]        ;Get comparison
  test r0d,r0d        ;Chk true
  jz %$true           ;Set if true
  mov p0q,s1q         ;Set cmp str
  lea p1q,[str_false] ;Set false str
  ccl [strcmp]        ;Get comparison
  test r0d,r0d        ;Chk false
  jz %$false          ;Set if false
  sub    rsp,0x40   ;Mke stack space for ptr
  mov    p1q,rsp    ;Set endptr since 0 is a valid value
  xor    p2d,p2d    ;Clr base
  ccl    [strtol]   ;Get val
  mov    p0q,[rsp]  ;Get endptr
  add    rsp,0x40   ;Rst stack
  cmpmb  [p0q],0    ;Chk pointing to 0
  jne    parse_errh ;Err if not
  xor    p0d,p0d    ;Clr p0d
  mov    p1d,0x01   ;Set p1d to 0x01
  test   r0d,r0d    ;Chk val
  cmovnz p0d,p1d    ;Set if value != 0
  mov    [s2q],p0d
  xor    r0d,r0d
  fnr    abis       ;Ret
  %$true:
   movmd [s2q],0x01
   xor    r0d,r0d
   fnr abic
  %$false:
   movmd [s2q],0x00
   xor    r0d,r0d
   fnr abic
  %pop ctx_parse_bool
 fn parse_errh, leaf, 0x10, line
  dbg_printf "Error occurred",10,0
  ccl [exit]
 fn on_exc,     leaf, 0x10, line
  lea rsp,[estack.end-0x100]
  dbg_onexc
  xor p0d,p0d
  ccl [exit]
 utilfunc:
  util_func_std
  util_func_compat
 align 0x1000, db 0
 code.end:
data:
 infile  dq 0
 outfile dq 0
 count   dq 0
 perline dq 0
 nasm    dd 0
 error   dd 0
 fopen_rd  db 'r',0
 fopen_wr  db 'w',0
 str_true  db 'true',0
 str_false db 'false',0
 str_comma db ',',0
 argstr:
  %assign idx 0
  %rep argidx
  argstr%[idx] db argdef%[idx],0
  %assign idx idx+1
  %endrep
 genstrtab fpf, fpf_idx
 utildata:
  util_data_std
  util_data_compat
 align 0x1000, db 0
 data.end:
prog_end