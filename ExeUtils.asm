;Todo - Find and note all non-local defines.
;Todo - Look into macro for better string table generation.

;Definitions
 %include "../../GenericUtils.asm"
 ;Note - Incomprehensible naming systems my beloved.
 %define byt0 0x000000FF      ;Byte0
 %define byt1 0x0000FF00      ;Byte1
 %define byt2 0x00FF0000      ;Byte2
 %define byt3 0xFF000000      ;Byte3
 %define prog 0x00000000      ;Program
 %define leaf 0x00000001      ;Leaf
 %define abic 0x00000002      ;ABI C
 %define abis 0x00000003      ;ABI (C) safe
 %define safe 0x00000004      ;Safe
 %define ydbg 0x00000100      ;Yes debug
 %define ndbg 0x00000200      ;No debug
 %define yspf 0x00000300      ;Yes profile
 %define nopf 0x00000400      ;No profile
 %define lneb 0x01000000      ;Line bit
 %define line lneb+__?LINE?__ ;Line
 ;Pass registers
 %macro defset 5
  %define %1q %2
  %define %1d %3
  %define %1w %4
  %define %1b %5
  %endmacro
 %ifidn platform, win64
  defset  s0, rbx,ebx, bx,  bl   ;Saved0
  defset  s1, rbp,ebp, bp,  bpl  ;Saved1
  defset  s2, r12,r12d,r12w,r12b ;Saved2
  defset  s3, r13,r13d,r13w,r13b ;Saved3
  defset  s4, r14,r14d,r14w,r14b ;Saved4
  defset  s5, r15,r15d,r15w,r15b ;Saved5
  defset  p0, rcx,ecx, cx,  cl   ;Pass0
  defset  p1, rdx,edx, dx,  dl   ;Pass1
  defset  p2, r8, r8d, r8w, r8b  ;Pass2
  defset  p3, r9, r9d, r9w, r9b  ;Pass3
  defset  u0, r10,r10d,r10w,r10b ;Unused0
  defset  u1, r11,r11d,r11w,r11b ;Unused1
  defset  h0, rdi,edi, di,  dil  ;Headache0
  defset  h1, rsi,esi, si,  sil  ;Headache1
  defset  r0, rax,eax, ax,  al   ;Return0
  %define pf0 xmm0               ;Passfloat0
  %define pf1 xmm1               ;Passfloat1
  %define pf2 xmm2               ;Passfloat2
  %define pf3 xmm3               ;Passfloat3
  ;Define long pass values up to 32 for convenience
  ;Very ugly but I can't be bothered
  %assign idx 0
  %rep 10 ;d00-d09
   %assign val%[idx] idx
   %define d0%[idx] [rsp+(0x20+(0x08*val%[idx]))]
   %assign idx idx+1
   %endrep
  %rep 22 ;d10-d31
   %assign val%[idx] idx
   %define d0%[idx] [rsp+(0x20+(0x08*val%[idx]))]
   %assign idx idx+1
   %endrep
  %endif
 %ifidn platform, linux
  defset  s0, rbx,ebx, bx,  bl   ;Saved0
  defset  s1, rbp,ebp, bp,  bpl  ;Saved1
  defset  s2, r12,r12d,r12w,r12b ;Saved2
  defset  s3, r13,r13d,r13w,r13b ;Saved3
  defset  s4, r14,r14d,r14w,r14b ;Saved4
  defset  s5, r15,r15d,r15w,r15b ;Saved5
  defset  p0, rdi,edi, di,  dil  ;Pass0
  defset  p1, rsi,esi, si,  sil  ;Pass1
  defset  p2, rdx,edx, dx,  dl   ;Pass2
  defset  p3, rcx,ecx, cx,  cl   ;Pass3
  defset  u0, r10,r10d,r10w,r10b ;Unused0
  defset  u1, r11,r11d,r11w,r11b ;Unused1
  defset  h0, r8, r8d, r8w, r8b  ;Headache0
  defset  h1, r9, r9d, r9w, r9b  ;Headache1
  defset  r0, rax,eax, ax,  al   ;Return0
  %define pf0 xmm0               ;Passfloat0
  %define pf1 xmm1               ;Passfloat1
  %define pf2 xmm2               ;Passfloat2
  %define pf3 xmm3               ;Passfloat3
  ;Define long pass values up to 32 for convenience
  %define d00 r8                 ;DPass0 special case
  %define d01 r9                 ;DPass1 special case
  %assign idx 2
  ;Define extended pass values up to 32 for convenience
  %rep 08 ;d02-d09
   %assign val%[idx] idx
   %define d0%[idx] [rsp+(0x20+(0x08*val%[idx]))]
   %assign idx idx+1
   %endrep
  %rep 22 ;d10-d31
   %assign val%[idx] idx
   %define d0%[idx] [rsp+(0x20+(0x08*val%[idx]))]
   %assign idx idx+1
   %endrep
  %endif
 ;Automation aliases
 defset auto0,  rax,eax, ax,  al
 defset auto1,  rbx,ebx, bx,  bl
 defset auto2,  rcx,ecx, cx,  cl
 defset auto3,  rdx,edx, dx,  dl
 defset auto4,  rdi,edi, di,  dil
 defset auto5,  rsi,esi, si,  sil
 defset auto6,  rbp,ebp, bp,  bpl
 defset auto7,  rsp,esp, sp,  spl
 defset auto8,  r8 ,r8d ,r8w ,r8b
 defset auto9,  r9 ,r9d ,r9w ,r9b
 defset auto10, r10,r10d,r10w,r10b
 defset auto11, r11,r11d,r11w,r11b
 defset auto12, r12,r12d,r12w,r12b
 defset auto13, r13,r13d,r13w,r13b
 defset auto14, r14,r14d,r14w,r14b
 defset auto15, r15,r15d,r15w,r15b
 %macro ccl 1
  ;Expects a bracketed parameter
  ;Note - Incomprehensible.
  %defstr %%cll_str0 %1
  %defstr %%cll_str1 %substr(%%cll_str0,2,-1)
  %strlen %%cll_len %%cll_str1
  %defstr %%cll_str2 %substr(%%cll_str1, 2, %%cll_len-3)
  %deftok %%cll_tok %%cll_str2
  %deftok %%cll_tok %%cll_tok
  call [%%cll_tok]
  %define %[%%cll_tok]_used
  %endmacro
 %macro cmv 2
  ;Note - Meant for conditional imports of memory variable instead of functions.
  ;Note - Not currently needed.
  %endmacro

;Common code
%macro guard_st 1
 %ifndef %1
 %define %1
 %endmacro
%macro guard_en 0
 %endif
 %endmacro
%macro util_common_dbg 0
 ;Note - This debug stuff could be handled a bit better
 %assign dbgidx 0     ;Note - should be dbg_lines or similar
 %assign dbg_stridx 0
 %macro dbg_line  2
  %assign %1_dbgidx dbgidx
  %define dbg%[dbgidx]_name %1
  %assign dbg%[dbgidx]_offs $-$$
  %assign dbg%[dbgidx]_line %2
  %assign dbgidx dbgidx+1
  %endmacro
 %macro dbg_printf 1+
  %define dbg_str%[dbg_stridx] %1
  lea p0q,[dbg_strl%[dbg_stridx]]
  %assign dbg_stridx dbg_stridx+1
  ccl [printf]
  %endmacro
 %macro dbg_guard 0
  cmpmd [dbg_rpt],0x01 ;Chk guard
  jne %%continue       ;Skip if not set
  dbg_printf           '[Exc] Secondary exception detected, exitting.',10,0
  xor p0d,p0d          ;Set -1
  not p0d              ;Set -1
  ccl [exit]           ;Exit
  %%continue:
  movmd [dbg_rpt],0x01 ;Set guard
  %endmacro
 %macro dbg_gprdump 0
  ;s0q, Register context
   lea s1q,[dbg_excreg]   ;Get register names
   mov s2d,0x11           ;Out GPRs + RIP
   %%gpr:                 ;Out GPRs
    mov p1q,s1q         ;Get register name
    mov p2q,[s0q]       ;Get register value
    dbg_printf          ' [Exc] [%s: 0x%016llX]',10,0
    add s0q,0x08        ;Adv register
    add s1q,0x04        ;Adv register name
    dec s2d             ;Dec count
    jnz %%gpr           ;Rpt
   %if dbgidx > 0
    %%rip:                 ;Out RIP line number
    sub  s0q,0x08         ;Sub to GPR base
    mov  p0q,[s0q]        ;Get RIP
    call util_dbg_getline ;Get line
    test r0d,r0d          ;Chk null
    jz %%rip_out          ;Out if not null
    %%rip_in:
     mov s0q,r0q
     dbg_printf '[Exc] Printing line nearest to RIP.',10,0
     mov p0q,s0q
     call util_dbg_printline
     jmp %%rip_done
    %%rip_out:
     dbg_printf '[Exc] No line found corrosponding to RIP.',10,0
    %%rip_done:
    %endif
   %endmacro
 %macro dbg_stkdump 2
  ;%1, Interval
  ;%2, Offset
  ;Note - This is not proper or reliable for general use cases.
  ;Note - May be broken by abis and safe. Didn't check. Definitely breaks on windows if the stack isn't aligned by 0x40.
  dbg_printf            '[Exc] Printing call path:',10,0
  mov s0q,[stack_base]  ;Get stack base
  mov s1d,(0x4000/%1)   ;Chk 16 KiB of stack data
  add s0q,%2            ;Add return address offset
  mov s2d,%2            ;Add return address offset
  %%loop:
   mov p0q,[s0q]
   call util_dbg_getline
   test r0q,r0q
   jz %%next
   mov s3q,r0q
   mov p1d,s2d
   dbg_printf ' [Exc] [RSP-0x%08llX]',0
   mov p0q,s3q
   call util_dbg_printline
   %%next:
   sub s0q,%1
   add s2d,%1
   dec s1d
   jnz %%loop
  %endmacro
 %endmacro
%macro util_compat_section 2
 ;%1, name
 ;%2, size
 %ifndef  secidx
 %assign  secidx 0
 %endif
 %ifndef imgtop
 %define imgtop roundu(end-$$, 0x1000)
 %endif
 %defstr  sec%[secidx].name %1
 %xdefine sec%[secidx].size %2
 %xdefine sec%[secidx].base imgtop
 %xdefine %1                ($$+(sec%[secidx].base))
 %xdefine %1.end            ($$+(sec%[secidx].base+sec%[secidx].size))
 %xdefine %1.size           %2
 %xdefine imgtop            (sec%[secidx].base+sec%[secidx].size)+0x1000
 %xdefine img.end          %1.end
 %assign secidx secidx+1
 %endmacro

;Compatibility packages
%ifidn platform, win64
%macro util_compat_stdc    0
 guard_st cpt_stdc
 addlib msvcr120.dll
 import _iob,       msvcr120.dll, forced ;Array that contains stdin/out/err
 import _get_errno, msvcr120.dll         ;Function to get errno
 import _set_errno, msvcr120.dll         ;Function to set errno
 %macro geterrno 0
  ccl [_get_errno]
  %endmacro
 %macro seterrno 0
  ccl [_set_errno]
  %endmacro
 guard_en
 %endmacro
%macro util_compat_cmdl    0
 guard_st cpt_cmdl
 addlib Kernel32.dll
 addlib msvcr120.dll
 addlib shell32.dll
 import GetCommandLineW,    Kernel32.dll
 import sprintf,            msvcr120.dll
 import CommandLineToArgvW, shell32.dll
 guard_en
 %endmacro
%macro util_compat_threads 0
 guard_st cpt_threads
 addlib msvcr120.dll
 import malloc,       msvcr120.dll
 import _beginthread, msvcr120.dll
 import _endthread,   msvcr120.dll
 %macro thr_make 2
  lea p0q,[%1]        ;Entry
  mov p1d,%2          ;Stack size
  xor p2d,p2d         ;Args
  ccl [_beginthread]
  %endmacro
 %macro thr_exit 0
  ccl [_endthread]
  %endmacro
 guard_en
 %endmacro
%macro util_compat_sleep   0
 guard_st cpt_sleep
 addlib Kernel32.dll
 import Sleep, Kernel32.dll
 %macro sleepms 1
  mov p0d,%1
  ccl [Sleep]
  %endmacro
 guard_en
 %endmacro
%macro util_compat_time    0
 guard_st cpt_time
 addlib Kernel32.dll
 import GetTickCount,            Kernel32.dll
 import GetSystemTimeAsFileTime, Kernel32.dll
 guard_en
 %endmacro
%macro util_compat_sock    0
 guard_st cpt_sock
 addlib Ws2_32.dll
 import WSAStartup,      Ws2_32.dll
 import closesocket,     Ws2_32.dll
 %macro sock_init 0
  sub rsp,0x40     ;Mke space for return data
  mov p0d,0x0202   ;Set flags
  mov p1q,rsp      ;Set return data ptr
  ccl [WSAStartup] ;Run
  add rsp,0x40     ;Rst stack
  %endmacro
 %macro sock_close 1
  mov p0d,%1
  ccl [closesocket]
  %endmacro
 guard_en
 %endmacro
%macro util_compat_exc     0
 guard_st cpt_exc
 addlib Kernel32.dll
 import AddVectoredExceptionHandler, Kernel32.dll
 util_compat_section estack, 0x10000
 %macro exc_handler 1
  xor p0d,p0d
  lea p1q,[%1]
  ccl [AddVectoredExceptionHandler]
  %endmacro
 guard_en
 %endmacro
%macro util_compat_dbg     0
 guard_st cpt_dbg
 addlib msvcr120.dll
 import printf, msvcr120.dll
 import exit,   msvcr120.dll
 util_common_dbg
 %macro dbg_onexc 0
  ;p0q, ExceptionPointers
   ;0x00 ExceptionRecord*
    ;dd 0x00000000         ;0x00 ExceptionCode
    ;dd 0x00000000         ;0x04 ExceptionFlags
    ;dq 0x0000000000000000 ;0x08 ExceptionRecord* (chain)
    ;dq 0x0000000000000000 ;0x10 ExceptionAddress*
    ;dd 0x00000000         ;0x18 NumberParameters
    ;dd 0x00000000         ;0x1C Padding
    ;dq 0x0000000000000000 ;0x20 ExceptionInformation
   ;0x08 ContextRecord* (abbreviated)
    ;dq 0x0000000000000000 ;0x00 P1Home (shadow space)
    ;dq 0x0000000000000000 ;0x08 P2Home (shadow space)
    ;dq 0x0000000000000000 ;0x10 P3Home (shadow space)
    ;dq 0x0000000000000000 ;0x18 P4Home (shadow space)
    ;dq 0x0000000000000000 ;0x20 P5Home (shadow space)
    ;dq 0x0000000000000000 ;0x28 P6Home (shadow space)
    ;dd 0x00000000         ;0x30 ContextFlags
    ;dd 0x00000000         ;0x34 MxCsr
    ;dw 0x0000             ;0x38 SegCs
    ;dw 0x0000             ;0x3A SegDs
    ;dw 0x0000             ;0x3C SegEs
    ;dw 0x0000             ;0x3E SegFs
    ;dw 0x0000             ;0x40 SegGs
    ;dw 0x0000             ;0x42 SegSs
    ;dd 0x00000000         ;0x44 EFlags
    ;dq 0x0000000000000000 ;0x48 Dr0
    ;dq 0x0000000000000000 ;0x50 Dr1
    ;dq 0x0000000000000000 ;0x58 Dr2
    ;dq 0x0000000000000000 ;0x60 Dr3
    ;dq 0x0000000000000000 ;0x68 Dr6
    ;dq 0x0000000000000000 ;0x70 Dr7
    ;dq 0x0000000000000000 ;0x78 Rax 0x00
    ;dq 0x0000000000000000 ;0x80 Rcx 0x08 WHY??
    ;dq 0x0000000000000000 ;0x88 Rdx 0x10
    ;dq 0x0000000000000000 ;0x90 Rbx 0x18 ???????????
    ;dq 0x0000000000000000 ;0x98 Rsp 0x20
    ;dq 0x0000000000000000 ;0xA0 Rbp 0x28
    ;dq 0x0000000000000000 ;0xA8 Rsi 0x30
    ;dq 0x0000000000000000 ;0xB0 Rdi 0x38
    ;dq 0x0000000000000000 ;0xB8 R8  0x40
    ;dq 0x0000000000000000 ;0xC0 R9  0x48
    ;dq 0x0000000000000000 ;0xC8 R10 0x50
    ;dq 0x0000000000000000 ;0xD0 R11 0x58
    ;dq 0x0000000000000000 ;0xD8 R12 0x60
    ;dq 0x0000000000000000 ;0xE0 R13 0x68
    ;dq 0x0000000000000000 ;0xE8 R14 0x70
    ;dq 0x0000000000000000 ;0xF0 R15 0x78
    ;dq 0x0000000000000000 ;0xF8 Rip 0x80
  dbg_guard
  mov s0q,[p0q+0x00]   ;Get ExceptionRecord
  mov s1q,[p0q+0x08]   ;Get ContextRecord
  mov p1d,[s0q+0x00]   ;Get ExceptionCode
  mov p2q,[s0q+0x10]   ;Get ExceptionAddress
  dbg_printf           '[Exc] Exception occurred with code [0x%08llX%]:',10,0
  lea s0q,[s1q+0x78]   ;Get GPR offset
  dbg_gprdump          ;Dmp GPRs
  %if dbgidx > 0
  %%stk: ;Cmp stack addresses to line numbers
  dbg_stkdump 0x40, 0x00
  %endif
  %endmacro
 guard_en
 %endmacro
%endif

%ifidn platform, linux
%macro util_compat_stdc    0
 guard_st cpt_stdc
 addlib libc.so.6
 import stdin,  x, forced
 import stdout, x, forced
 import stderr, x, forced
 import __errno_location
 %macro geterrno 0
  mov r0q,[c_errptr]
  mov r0d,[r0q]
  %endmacro
 %macro seterrno 0
  mov r0q,[c_errptr]
  mov [r0q],p0d
  %endmacro
 guard_en
 %endmacro
%macro util_compat_cmdl    0
 %define cpt_cmdl
 %endmacro
%macro util_compat_threads 0
 guard_st cpt_threads
 addlib libc.so.6
 import malloc
 import clone
 import exit
 %macro thr_make 2
  mov p0d,%2         ;4 KiB stack space
  ccl [malloc]       ;Allocate stack space
  add r0q,0xFF8      ;Stack grows downwards
  mov p1q,r0q        ;Set the stack
  lea p0q,[%1]       ;Set the thread entry
  mov p2d,0x00010F00 ;Share VM, share filesystem, share fds, same thread
  xor p3d,p3d        ;No args
  ccl [clone]
  %endmacro
 %macro thr_exit 0
  fnr abic
  %endmacro
 guard_en
 %endmacro
%macro util_compat_sleep   0
 guard_st cpt_sleep
 addlib libc.so.6
 import usleep
 %macro sleepms 1
  mov p0d,%1*1000
  ccl [usleep]
  %endmacro
 guard_en
 %endmacro
%macro util_compat_time    0
 guard_st cpt_time
 addlib libc.so.6
 import gettimeofday
 guard_en
 %endmacro
%macro util_compat_sock    0
 guard_st cpt_sock
 addlib libc.so.6
 import close
 %macro sock_init 0
  xor r0d,r0d
  %endmacro
 %macro sock_close 1
  mov p0d,%1
  ccl [close]
  %endmacro
 guard_en
 %endmacro
%macro util_compat_exc     0
 guard_st cpt_exc
 addlib libc.so.6
 import sigaction
 import sigaltstack
 util_compat_section estack, 0x10000
 %macro exc_handler 1
  ;Sigaction struct
   ;0x00-0x07 Handler
   ;0x08-0x87 Mask
   ;0x88-0x8B Flags
   ;0x8C-0x8F Padding? I forget
   ;0x90-0x97 Restorer
  ;Signums set
   ;0x02 (0x0004) ;SIGINT
   ;0x04 (0x0010) ;SIGILL
   ;0x06 (0x0040) ;SIGABRT
   ;0x08 (0x0100) ;SIGFPE
   ;0x0B (0x0800) ;SIGSEGV
   ;0x0F (0x8000) ;SIGTERM
  sub rsp,0xA0                    ;Mke stack space for the struct
  xor r0d,r0d                     ;Clr rax
  mov p0q,rsp                     ;Get mask ptr
  mov p1d,0x13                    ;Set 0x13 qwords (0x98 bytes)
  %%clrloop:                      ;Clr mask
   mov [p0q],r0q ;Clr qword
   add p0q,0x08  ;Adv ptr
   dec p1d       ;Dec count
   jnz %%clrloop ;Rpt
  lea r0q,[%1]                    ;Get exception handler
  mov p0d,0x08000004              ;Set SA_SIGINFO and SA_ONSTACK
  mov qword[rsp+0x00],r0q         ;Set handler
  mov dword[rsp+0x88],p0d         ;Set flags
  mov s0d,0x8954                  ;Bitmask for desired signums
  %%setsigs:
   bsf p0d,s0d     ;Set signum
   jz %%done       ;Ext if (bfs == 0)
   mov p1q,rsp     ;Set sigaction struct
   xor p2d,p2d     ;Clr sa_restore
   ccl [sigaction] ;Run sigaction
   blsr s0d,s0d    ;Clr lowest set bit
   jmp %%setsigs   ;Rpt
  %%done:
  lea p0q,[estack]                     ;Get exception stack
  xor p1d,p1d                          ;Clr flags
  mov p2d,estack.size                  ;Set stack size
  mov [rsp+0x00],p0q                   ;Set stack
  mov [rsp+0x08],p1q                   ;Set flags
  mov [rsp+0x10],p2q                   ;Set stack size
  mov p0q,rsp                          ;Set stack_t struct
  xor p1d,p1d                          ;Clr old stack
  ccl [sigaltstack]                    ;Run
  add rsp,0xA0                         ;Rst stack
  %endmacro
 guard_en
 %endmacro
%macro util_compat_dbg     0
 guard_st cpt_dbg
 addlib libc.so.6
 import printf
 util_common_dbg
 %macro dbg_onexc 0
  ;p0d, signum
  ;p1q, siginfo_t*
   ;dd 0x00000000 ;0x00 si_signo
   ;dd 0x00000000 ;0x04 si_errno
   ;dd 0x00000000 ;0x08 si_code
   ;And so on
  ;p2q, ucontext_t*
   ;dq 0x0000000000000000 ;0x00 uc_flags
   ;dq 0x0000000000000000 ;0x08 uc_link*
   ;dq 0x0000000000000000 ;0x10 stack_t.ss_sp*
   ;dd 0x00000000         ;0x18 stack_t.ss_flags
   ;dd 0x00000000         ;0x1C stack_t (padding)
   ;dq 0x0000000000000000 ;0x20 stack_t.ss_size
   ;dq 0x0000000000000000 ;0x28 Start of mcontext_t (R8)
   ;And so on
  dbg_guard
  lea s0q,[p2q+0x28]
  mov p1d,p0d
  dbg_printf "[Exc] Exception occured with signum [%i]",10,0
  dbg_gprdump
  %if dbgidx > 0
  dbg_stkdump 0x10, 0x08
  %endif
  %endmacro
 guard_en
 %endmacro
%endif
%macro util_compat_all     0
 util_compat_stdc
 util_compat_cmdl
 util_compat_threads
 util_compat_sleep
 util_compat_time
 util_compat_sock
 util_compat_exc
 util_compat_dbg
 %endmacro

;Functionality packages
%macro util_func_pf  0
 guard_st cpt_pf
 %ifidn platform, win64
  addlib msvcr120.dll
  import printf, msvcr120.dll
  %endif
 %ifidn platform, linux
  addlib libc.so.6
  import printf
  %endif
 %define pfidx 0
 %macro pf_st 1 ;Start
  %define pf%[pfidx]_name %1 ;Def name
  inc qword [%1_runcount]    ;Inc runcount
  call util_timeus           ;Get runstart
  mov [%1_runstart],r0q      ;Set runstart
  %assign pfidx pfidx+1
  %endmacro
 %macro pf_en 1 ;End
  call util_timeus           ;Get runtime
  sub r0q,[%1_runstart]      ;Get runtime
  add [%1_runtime],r0q       ;Add runtime
  %endmacro
 %macro pf_ig 1 ;Ignore
  %define pf_ignore
  %endmacro
 %macro pf_wr 1 ;Write
  lea p0q,[pf_print]
  mov p1q,[%1_runcount]
  mov p2q,[%1_runtime]
  lea p3q,[%1_str]
  ccl [printf]
  %endmacro
 %macro pf_wa 0 ;Write all
  %assign idx 0
  %rep pfidx
  pf_wr pf%[idx]_name
  %assign idx idx+1
  %endrep
  %endmacro
 guard_en
 %endmacro
%macro util_func_all 0
 util_func_pf
 %endmacro

;Necessary program macros
%macro fn_pre 1-*.nolist
 %rep %0
  %if %1 == ydbg
   %define dbg_enable
   %endif
  %if %1 == ndbg
   %define dbg_ignore
   %endif
  %if %1 == yspf || %isdef(pf_allfuncs)
   %define pf_enable
   %undef  pf_ignore
   %endif
  %if %1 == nopf
   %define pf_ignore
   %endif
  %if %1 & byt3 == lneb
   dbg_line line_name, (%1 & 0x00FFFFFF)
   %endif
  %rotate 1
  %endrep
 %endmacro
%macro fn_post 1
 %if (%isdef(pf_allfuncs) || %isdef(pf_enable)) && %isndef(pf_ignore)
 pf_st pf_auto_%1
 %define pf_last pf_auto_%1
 %undef pf_enable
 %endif
 %endmacro
%macro fnr_pre 0
 %if %isdef(pf_allfuncs) && %isndef(pf_ignore)
  pf_en pf_last
  %endif
 %endmacro
%ifidn platform, win64
 %macro prog_init 0
  %ifdef cpt_dbg
   mov [stack_base],rsp
   %endif
  sub rsp,0x38 ;Initilize the stack
  %ifdef cpt_stdc
   mov rax,[_iob]
   lea rbx,[rax+0x30]
   lea rcx,[rax+0x60]
   mov [c_stdin],rax
   mov [c_stdout],rbx
   mov [c_stderr],rcx
   %endif
  %ifdef cpt_cmdl
   ;Requires the inclusion of both Kernel32.dll and more importantly shell32.dll
   ;There are some dubious things with this but the alternative is rather terrible
   ccl [GetCommandLineW]
   mov p0q,r0q
   lea p1q,[argc]
   ccl [CommandLineToArgvW]
   mov [argv],r0q
   mov s0d,[argc] ;s0d, argc
   mov s1q,r0q    ;s1q, argv
   %%argv_gen:
    ;Somewhat hacky solution with reading and writing at the same address and using sprintf instead of WideCharToMultiByte
    ;That said it works fine on my machine
    mov p0q,[s1q]       ;Output to  argv[n]
    lea p1q,[print_cnv] ;Convert the string
    mov p2q,[s1q]       ;Input from argv[n]
    ccl [sprintf]       ;Convert string. UTF8 should always be smaller than LPWSTR
    add s1q,0x08        ;Advance to next pointer
    dec s0d             ;Decrement count
    jnz %%argv_gen
   %endif
  %endmacro
 %macro fn 2-4+.nolist
  %if %0 >= 3 ;Optional function alignment
   align %3
   %endif
  %1:
  %if %0 >= 4 ;Optional parameters
   %define line_name %1 ;Note - Ugly.
   fn_pre %4
   %endif
  %if %2 == prog ;Program entry
   prog_init
   %endif
  %if %2 == leaf ;Leaf function   / no ABI calls
   %endif
  %if %2 == abic ;Branch function / makes ABI calls
   sub rsp,0x38
   %endif
  %if %2 == abis ;Safe function   / saves ABI preserved registers
   call util_push_abi
   sub rsp,0x38
   %endif
  %if %2 == safe ;Safe function   / saves all registers
   call util_push
   sub rsp,0x40
   %endif
  fn_post %1
  %endmacro
 %macro fnr 1
  fnr_pre
  %if %1 == leaf
   ret
   %endif
  %if %1 == abic
   add rsp,0x38
   ret
   %endif
  %if %1 == abis
   add rsp,0x38
   jmp util_pop_abi
   %endif
  %if %1 == safe
   add rsp,0x40
   jmp util_pop
   %endif
  %endmacro
 %endif
%ifidn platform, linux
 %macro prog_init 0
  %ifdef cpt_dbg
   mov [stack_base],rsp
   %endif
  %ifdef cpt_stdc
   mov rax,[stdin]
   mov rbx,[stdout]
   mov rcx,[stderr]
   mov rax,[rax]
   mov rbx,[rbx]
   mov rcx,[rcx]
   mov [c_stdin],rax
   mov [c_stdout],rbx
   mov [c_stderr],rcx
   ccl [__errno_location]
   mov [c_errptr],r0q
   %endif
  %ifdef cpt_cmdl
   mov eax,[rsp]
   mov [argc],eax
   lea rax,[rsp+0x08]
   mov [argv],rax
   sub rsp,0x10
   %endif
  %endmacro
 %macro fn 2-4+.nolist
  %if %0 >= 3 ;Optional function alignment
   align %3
   %endif
  %if %0 >= 4 ;Optional parameters
   %define line_name %1 ;Note - Ugly.
   fn_pre %4
   %endif
  %1:
  %if %2 == prog ;Program entry
   prog_init
   %endif
  %if %2 == leaf ;Leaf function   / no ABI calls
   %endif
  %if %2 == abic ;Branch function / makes ABI calls
   sub rsp,0x08
   %endif
  %if %2 == abis ;Safe function   / saves ABI preserved registers
   call util_push_abi
   %endif
  %if %2 == safe ;Safe function   / saves all registers
   call util_push
   %endif
  fn_post %1
  %endmacro
 %macro fnr 1
  fnr_pre
  %if %1 == leaf
   ret
   %endif
  %if %1 == abic
   add rsp,0x08
   ret
   %endif
  %if %1 == abis
   jmp util_pop_abi
   %endif
  %if %1 == safe
   jmp util_pop
   %endif
  %endmacro
 %endif

;Code/data
%macro util_func_std    0 ;Misc utility functions
 ;Todo - Have strict 0x40 stack alignment on windows. Maybe add some debug info optionally pushed to stack for both windows/linux.
 ;Todo - push_abi and pop_abi were completely broken. Did a quick fix but need to iron them out.
 fn util_push_abi, leaf, 0x10
  mov rax,[rsp]
  %ifidn platform, win64
  push h1q
  push h0q
  %endif
  push s5q
  push s4q
  push s3q
  push s2q
  push s1q
  push s0q
  push rax
  ret
 fn util_pop_abi,  leaf, 0x10
  pop s0q
  pop s1q
  pop s2q
  pop s3q
  pop s4q
  pop s5q
  %ifidn platform, win64
  pop h0q
  pop h1q
  %endif
  add rsp,0x08
  ret
 fn util_push,     leaf, 0x10
  xchg rax,[rsp]
  push rbx
  push rcx
  push rdx
  push rdi
  push rsi
  push rbp
  push r8
  push r9
  push r10
  push r11
  push r12
  push r13
  push r14
  push r15
  push rax
  mov rax,[rsp+0x78]
  ret
 fn util_pop,      leaf, 0x10
  pop r15
  pop r14
  pop r13
  pop r12
  pop r11
  pop r10
  pop r9
  pop r8
  pop rbp
  pop rsi
  pop rdi
  pop rdx
  pop rcx
  pop rbx
  pop rax
  ret
 %endmacro
%macro util_func_compat 0 ;Cross-platform functions
 %ifidn platform, win64
  %ifdef cpt_time
   fn util_timems, abic, 0x10, nopf
    lea p0q,[timestamp]
    ccl [GetTickCount]
    fnr abic
   fn util_timeus, abis, 0x10, nopf
    lea p0q,[timestamp]
    ccl [GetSystemTimeAsFileTime]
    mov rax,[timestamp]
    push rbx
    push rdx
    xor edx,edx
    mov ebx,10
    div ebx
    pop rdx
    pop rbx
    fnr abis
   %endif
  %endif
 %ifidn platform, linux
  %ifdef cpt_time
   fn util_timems, abis, nopf
    lea p0q,[timestamp]
    xor p1q,p1q
    ccl [gettimeofday]
    push rbx
    push rcx
    push rdx
    mov rax,[timestamp+0x08]
    xor edx,edx
    mov ebx,1000
    div rbx
    mov rcx,rax
    mov rax,[timestamp+0x00]
    mov ebx,1000
    mul rbx
    add rax,rcx
    pop rdx
    pop rcx
    pop rbx
    fnr abis
   fn util_timeus, abis, nopf
    lea p0q,[timestamp]
    xor p1q,p1q
    ccl [gettimeofday]
    mov rax,[timestamp+0x00]
    mov rcx,[timestamp+0x08]
    mov ebx,1000000
    mul rbx
    add rax,rcx
    fnr abis
   %endif
  %endif
 %ifdef cpt_dbg
  fn util_dbg_printline, abic, nopf
   ;p0q, line
   sub rsp,0x40
   lea u0q,[img]
   mov p1d,[p0q+0x00] ;Get file offset
   mov p3d,[p0q+0x00] ;Get file offset for address
   mov p2d,[p0q+0x04] ;Get code offset
   mov u1d,[p0q+0x08] ;Get line number
   mov r0d,[p0q+0x0C] ;Get string offset
   add p3q,u0q        ;Get address
   add r0q,u0q        ;Get string address
   mov d00,u1q        ;Set line number
   mov d01,r0q        ;Set string
   dbg_printf         ' [FileOffset: 0x%08llX] [CodeOffset: 0x%08llX] [Address: 0x%016llX] [LineNumber: %06i] [%s]',10,0
   add rsp,0x40
   fnr abic
  fn util_dbg_printall,  abis, nopf
   lea s0q,[dbg_dat]
   mov s1d,dbgidx      ;Get debug count
   %%dbg_print:        ;Out debug data
    mov p0q,s0q
    call util_dbg_printline
    add s0q,0x10       ;Adv debug data
    dec s1d            ;Rpt
    jnz %%dbg_print    ;Rpt
   fnr abis
  fn util_dbg_getline,   abic, nopf
   ;p0q, address
   ;Check in code range
    xor r0d,r0d        ;Clr r0d
    lea u0q,[code]     ;Get Code
    lea u1q,[code.end] ;Get CodeEnd
    cmp p0q,u0q        ;Chk Addr < Code
    jl %%udgl_done     ;Chk Addr < Code
    cmp p0q,u1q        ;Chk Addr > CodeEnd
    jg %%udgl_done     ;Chk Addr > CodeEnd
   lea u0q,[img]      ;Get image base
   lea u1q,[dbg_dat]  ;Get debug data
   mov p2d,dbgidx     ;Get line count
   util_dbg_getline_loop:
    mov   p1d,[u1q] ;Get file offset
    add   p1q,u0q   ;Get addres
    cmp   p0q,p1q   ;Chk InAddr < EntAddr
    cmovg r0q,u1q   ;Set debug data entry
    add   u1q,0x10  ;Adv debug data
    dec   p2d       ;Dec count
    jnz util_dbg_getline_loop
   %%udgl_done:
   fnr abic
  %endif
 %endmacro
%macro util_data_std    0 ;Data required by funcs_std
 align 0x08, db 0
 print_r64 db '0x%016llX',10,0
 print_r32 db '0x%08llX',10,0
 print_r16 db '0x%04llX',10,0
 print_r08 db '0x%02llX',10,0
 %endmacro
%macro util_data_compat 0 ;Data required by data_compat
 %ifdef cpt_stdc
  align 0x08, db 0
  c_stdin  dq 0
  c_stdout dq 0
  c_stderr dq 0
  c_errptr dq 0
  %endif
 %ifdef cpt_cmdl
  align 0x08, db 0
  argv        dq 0
  argc        dd 0
  %ifidn platform, win64
  print_cnv   db '%ls',0
  %endif
  %endif
 %ifdef cpt_time
  align 0x08, db 0
  timestamp times 0x10 db 0
  %endif
 %ifdef cpt_dbg
  align 0x08, db 0
  stack_base  dq 0
  dbg_rpt     dd 0
  %assign idx 0 ;Debug data
   dbg_dat:
   %rep dbgidx
   dbgdat%[idx]_addr dd dbg%[idx]_offs        ;0x00 File offset
   dbgdat%[idx]_offs dd dbg%[idx]_offs - code ;0x04 Offset from base of code
   dbgdat%[idx]_line dd dbg%[idx]_line        ;0x08 Line
   dbgdat%[idx]_stri dd dbgdat%[idx]_name     ;0x0C Name index
   %assign idx idx+1
   %endrep
  %assign idx 0 ;Debug string table
   dbg_str:
   %rep dbgidx
   %if %isstr(dbg%[idx]_name)
    %define strname dbg%[idx]_name
   %else
    %defstr strname dbg%[idx]_name
    %endif
   dbgdat%[idx]_name db strname,0
   %assign idx idx+1
   %endrep
  %assign idx 0 ;dbg_printf table
   %rep dbg_stridx
   dbg_strl%[idx] db dbg_str%[idx]
   %assign idx idx+1
   %endrep
  %ifidn platform, win64
   dbg_excreg:
    db 'RAX',0
    db 'RCX',0
    db 'RDX',0
    db 'RBX',0
    db 'RSP',0
    db 'RBP',0
    db 'RSI',0
    db 'RSI',0
    db 'R8 ',0
    db 'R9 ',0
    db 'R10',0
    db 'R11',0
    db 'R12',0
    db 'R13',0
    db 'R14',0
    db 'R15',0
    db 'RIP',0
   %endif
  %ifidn platform, linux
   dbg_excreg:
    db 'R8 ',0
    db 'R9 ',0
    db 'R10',0
    db 'R11',0
    db 'R12',0
    db 'R13',0
    db 'R14',0
    db 'R15',0
    db 'RDI',0
    db 'RSI',0
    db 'RBP',0
    db 'RBX',0
    db 'RDX',0
    db 'RAX',0
    db 'RCX',0
    db 'RSP',0
    db 'RIP',0
   %endif
  %endif
 %ifdef cpt_pf
  align 0x08, db 0
  %assign idx 0
  %rep pfidx ;Generate data
   %define pfname pf%[idx]_name
   %[pfname]_runcount dq 0
   %[pfname]_runstart dq 0
   %[pfname]_runtime  dq 0
   %assign idx idx+1
   %endrep
  %assign idx 0
  %rep pfidx ;Generate strings
   %defstr pfname pf%[idx]_name
   pfname%[idx]:
   %[pf%[idx]_name]_str:
   db pfname,0
   %assign idx idx+1
   %endrep
  pf_print db ' [RunCount: 0x%016llX] [MicroSeconds: 0x%016llX] [%s]',10,0
  %endif
 %endmacro