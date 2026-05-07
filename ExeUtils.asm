;Todo - switch to context local defines

;Definitions
 %include "../../GenericUtils.asm"
 %define prog 0x00
 %define leaf 0x01
 %define abic 0x02
 %define abis 0x03
 %define safe 0x04
 %define line __?LINE?__
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
  %define idx 0
  %rep 10 ;d00-d09
   %define d0%[idx] [rsp+(0x20+(0x08*idx))]
   %assign idx idx+1
   %endrep
  %rep 22 ;d10-d31
   %define d%[idx] [rsp+(0x20+(0x08*idx))]
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
  %define idx 2
  ;Define extended pass values up to 32 for convenience
  %rep 08 ;d02-d09
   %define d0%[idx] [rsp+(0x08*(idx-2))]
   %assign idx idx+1
   %endrep
  %rep 22 ;d10-d31
   %define d%[idx] [rsp+(0x08*(idx-2))]
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
  %defstr cxll_str0 %1
  %defstr cxll_str1 %substr(cxll_str0,2,-1) ;Remove first char
  %strlen cxll_len cxll_str1
  %defstr cxll_str2 %substr(cxll_str1, 2, cxll_len-3)
  %deftok cxll_tok cxll_str2
  %deftok cxll_tok cxll_tok
  call [cxll_tok]
  %define %[cxll_tok]_used
  %endmacro
 %macro cmv 2
  
  %endmacro

;Compatibility packages
%macro guard_st 1
 %ifndef %1
 %define %1
 %endmacro
%macro guard_en 0
 %endif
 %endmacro
%ifidn platform, win64
 %macro util_compat_stdc    0
  guard_st cpt_stdc
  addlib msvcr120.dll
  import _iob,       msvcr120.dll, forced ;Array that contains stdin/out/err
  import _get_errno, msvcr120.dll, forced ;Function to get errno
  %macro geterrno 0
   ccl [_get_errno]
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
   sub rsp,0x20
   mov p0d,0x0202
   mov p1q,rsp
   ccl [WSAStartup]
   add rsp,0x20
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
  %macro exc_handler 1
   xor p0d,p0d
   lea p1q,[%1]
   ccl [AddVectoredExceptionHandler]
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
   mov r0q,[r0q]
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
   ccl [malloc]      ;Allocate stack space
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
   sub rsp,0xA0             ;Mke stack space for the struct
   xor r0d,r0d              ;Clr rax
   mov p0q,rsp              ;Get mask ptr
   mov p1d,0x13             ;Set 0x13 qwords (0x98 bytes)
   %%clrloop:               ;Clr mask
    mov [p0q],r0q ;Clr qword
    add p0q,0x08  ;Adv ptr
    dec p1d       ;Dec count
    jnz %%clrloop ;Rpt
   lea r0q,[%1]             ;Get exception handler
   mov qword[rsp+0x00],r0q  ;Set handler
   mov dword[rsp+0x88],0x04 ;Set flags
   mov s0d,0x8954           ;Bitmask for desired signums
   %%setsigs:
    bsf p0d,s0d     ;Set signum
    jz %%done       ;Ext if (bfs == 0)
    mov p1q,rsp     ;Set sigaction struct
    xor p2d,p2d     ;Clr sa_restore
    ccl [sigaction] ;Run sigaction
    blsr s0d,s0d    ;Clr lowest set bit
    jmp %%setsigs   ;Rpt
   %%done:
   add rsp,0xA0
   %endmacro
  guard_en
  %endmacro
 %endif
%macro util_compat_dbg   0
 guard_st cpt_dbg
 %ifidn platform, win64
  addlib msvcr120.dll
  import printf, msvcr120.dll
  %endif
 %ifidn platform, linux
  addlib libc.so.6
  import printf
  %endif
 %assign dbgidx 0
 %macro dbg_line 2
  %assign %1_dbgidx dbgidx
  %define dbg%[dbgidx]_name %1
  %assign dbg%[dbgidx]_offs $-$$
  %assign dbg%[dbgidx]_line %2
  %assign dbgidx dbgidx+1
  %endmacro
 guard_en
 %endmacro
%macro util_compat_pf    0
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
%macro util_compat_bss   0
 guard_st cpt_bss
 %ifndef bss.size
 %define bss.size 0x1000
 %macro compat_bssgen 0
  %define bss.stt roundu((end-$$),0x1000)
  %define bss     ($$+bss.stt)
  %define bss.end ($$+(bss.stt+bss.size))
  %define bss.ien (bss.stt+bss.size)
  %define imgsz   bss.ien
  %endmacro
 %endif
 guard_en
 %endmacro
%macro util_compat_stack 0
 guard_st cpt_stk
 %ifndef stk.size
 ;Note - From testing at least 16 KiB is necessary on linux to prevent random crashes.
 ;Note - No crashes yet with 4 KiB on windows, but 64 KiB seems to be a recommendation.
 ;Note - Linux stack overflow crashes fail to trigger the exception handler.
 %define stk.size 0x10000
 %macro compat_stkgen 0
  %ifndef bss.end
  %define bss.end roundu(end-$$,0x1000)
  %endif
  %define stk.stt (roundu(bss.ien, 0x1000)+0x1000)
  %define stk     ($$+stk.stt)
  %define stk.end ($$+(stk.stt+stk.size))
  %define stk.ien (stk.stt+stk.size)
  %define imgsz   stk.ien
  %endmacro
 %endif
 guard_en
 %endmacro
%macro util_compat_all   0
 util_compat_stdc
 util_compat_cmdl
 util_compat_threads
 util_compat_sleep
 util_compat_time
 util_compat_sock
 util_compat_exc
 util_compat_dbg
 util_compat_pf
 util_compat_bss
 util_compat_stack
 %endmacro

;Necessary program macros
;Note - Might make sense to re-merge fn and fnr given how much shared code they now have.
%ifidn platform, win64
 %macro prog_init 0
  %ifdef cpt_stk
   lea rsp,[stk+(stk.size-0x100)]
   lea rax,[stk]
   lea rbx,[rax+stk.size]
   mov [stack_bot],rax
   mov [stack_top],rbx
  %else
   sub rsp,0x38 ;Initilize the stack
   %endif
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
 %macro fn 2-4
  %if %0 >= 3 ;Optional function alignment
   align %3
   %endif
  %if %0 == 4 ;Optional line number generation
   dbg_line %1, %4
   %endif
  %1:
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
  %define pf_last pf_auto_%1
  %if %isdef(pf_allfuncs) && %isnidn(%1, util_timeus)
   pf_st pf_auto_%1
   %endif
  %endmacro 
 %macro fnr 1
  %if %isdef(pf_allfuncs) && %isnidn(pf_last, pf_auto_util_timeus)
   pf_en pf_last
   %endif
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
  %ifdef cpt_stk
   lea rsp,[stk+(stk.size-0x10)]
   lea rax,[stk]
   lea rbx,[rax+stk.size]
   mov [stack_bot],rax
   mov [stack_top],rbx
   %endif
  %endmacro
 %macro fn 2-4
  %if %0 >= 3 ;Optional function alignment
   align %3
   %endif
  %if %0 == 4 ;Optional line number generation
   dbg_line %1, %4
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
  %define pf_last pf_auto_%1
  %if %isdef(pf_allfuncs) && %isnidn(%1, util_timeus)
   pf_st pf_auto_%1
   %endif
  %endmacro
 %macro fnr 1
  %if %isdef(pf_allfuncs) && %isnidn(pf_last, pf_auto_util_timeus)
   pf_en pf_last
   %endif
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
 util_push_abi:
  mov  rax,[rsp]
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
 util_pop_abi:
  pop s0q
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
  ret
 util_push:
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
 util_pop:
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
 fn util_printr0q, safe
  lea p0q,[print_r64]
  mov p1q,r0q
  ccl [printf]
  fnr safe
 fn util_printr0d, safe
  lea p0q,[print_r32]
  mov p1d,r0d
  ccl [printf]
  fnr safe
 fn util_printr0w, safe
  lea p0q,[print_r16]
  movzx p1d,r0w
  ccl [printf]
  fnr safe
 fn util_printr0b, safe
  lea p0q,[print_r08]
  movzx p1d,r0b
  ccl [printf]
  fnr safe
 %endmacro
%macro util_func_compat 0 ;Cross-platform functions
 %ifidn platform, win64
  %ifdef cpt_time
   fn util_timems, abic
    lea p0q,[timestamp]
    ccl [GetTickCount]
    fnr abic
   fn util_timeus, abis
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
   fn util_timems, abis
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
   fn util_timeus, abis
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
  fn util_dbg_printall, abis
  lea s0q,[dbg_dat]      ;Get debug data
  lea s1q,[img]          ;Get image base
  mov s3d,dbgidx         ;Get debug count
  %%dbg_print:           ;Out debug data
   lea p0q,[dbg_out0] ;Get string0
   mov p1d,[s0q+0x00] ;Get file offset
   mov p3d,[s0q+0x00] ;Get file offset
   mov p2d,[s0q+0x04] ;Get code offset
   add p3q,s1q        ;Get address
   ccl [printf]       ;Out
   lea p0q,[dbg_out1] ;Get string1
   mov p1d,[s0q+0x08] ;Get line
   mov p2d,[s0q+0x0C] ;Get string index
   add p2q,s1q        ;Get string address
   ccl [printf]       ;Out
   add s0q,0x10       ;Adv debug data
   dec s3d            ;Rpt
   jnz %%dbg_print    ;Rpt
  fnr abis
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
  %assign idx 0
  dbg_dat:
  %rep dbgidx
   dbgdat%[idx]_addr dd dbg%[idx]_offs        ;0x00 File offset
   dbgdat%[idx]_offs dd dbg%[idx]_offs - code ;0x04 Offset from base of code
   dbgdat%[idx]_line dd dbg%[idx]_line        ;0x08 Line
   dbgdat%[idx]_stri dd dbgdat%[idx]_name     ;0x0C Name index
   %assign idx idx+1
   %endrep
  %assign idx 0
  dbg_str:
  %rep dbgidx
   %defstr strname dbg%[idx]_name
   dbgdat%[idx]_name db strname,0
   %assign idx idx+1
   %endrep
  %endif
  dbg_out0 db '[FileOffset: 0x%08llX] [CodeOffset: 0x%08llX] [Address: 0x%016llX] ',0
  dbg_out1 db '[LineNumber: %06i] [%s]',10,0
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
  pf_print db '[RunCount: 0x%016llX] [MicroSeconds: 0x%016llX] [%s]',10,0
  %endif
 %ifdef cpt_stk
  align 0x08, db 0
  stack_bot dq 0
  stack_top dq 0
  %endif
 %endmacro