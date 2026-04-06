;Definitions
 %include "../../GenericUtils.asm"
 %define leaf 0x00
 %define abic 0x01
 %define abis 0x02
 %define safe 0x03
 ;Pass registers
 %ifidn platform, win64
  %define p0q rcx
  %define p1q rdx
  %define p2q r8
  %define p3q r9
  %define p4q qword [rsp+0x20]
  %define p5q qword [rsp+0x28]
  %define p6q qword [rsp+0x30]
  %define p7q qword [rsp+0x38]
  %define p8q qword [rsp+0x40]
  %define p9q qword [rsp+0x48]
  %define r0q rax
  %define p0d ecx
  %define p1d edx
  %define p2d r8d
  %define p3d r9d
  %define r0d eax
  %define p0w cx
  %define p1w dx
  %define p2w r8w
  %define p3w r9w
  %define r0w ax
  %define p0b cl
  %define p1b dl
  %define p2b r8b
  %define p3b r9b
  %define r0b al
  %define pf0 xmm0
  %define pf1 xmm1
  %define pf2 xmm2
  %define pf3 xmm3
  %define s0q rbx
  %define s1q rbp
  %define s2q r12
  %define s3q r13
  %define s4q r14
  %define s5q r15
  %define s0d ebx
  %define s1d ebp
  %define s2d r12d
  %define s3d r13d
  %define s4d r14d
  %define s5d r15d
  %define s0w bx
  %define s1w bp
  %define s2w r12w
  %define s3w r13w
  %define s4w r14w
  %define s5w r15w
  %define s0b bl
  %define s1b bpl
  %define s2b r12b
  %define s3b r13b
  %define s4b r14b
  %define s5b r15b
  %define u0q r10
  %define u1q r11
  %define u0d r10d
  %define u1d r11d
  %define u0w r10w
  %define u1w r11w
  %define u0b r10b
  %define u1b r11b
  %endif
 %ifidn platform, linux
  %define p0q rdi
  %define p1q rsi
  %define p2q rdx
  %define p3q rcx
  %define p4q r8
  %define p5q r9
  %define p6q qword[rsp+0x00]
  %define p7q qword[rsp+0x08]
  %define p8q qword[rsp+0x10]
  %define p9q qword[rsp+0x18]
  %define r0q rax
  %define p0d edi
  %define p1d esi
  %define p2d edx
  %define p3d ecx
  %define p4d r8d
  %define p5d r9d
  %define r0d eax
  %define p0w di
  %define p1w si
  %define p2w dx
  %define p3w cx
  %define r0w ax
  %define p0b dil
  %define p1b sil
  %define p2b dl
  %define p3b cl
  %define r0b al
  %define pf0 xmm0
  %define pf1 xmm1
  %define pf2 xmm2
  %define pf3 xmm3
  %define s0q rbx
  %define s1q rbp
  %define s2q r12
  %define s3q r13
  %define s4q r14
  %define s5q r15
  %define s0d ebx
  %define s1d ebp
  %define s2d r12d
  %define s3d r13d
  %define s4d r14d
  %define s5d r15d
  %define s0w bx
  %define s1w bp
  %define s2w r12w
  %define s3w r13w
  %define s4w r14w
  %define s5w r15w
  %define s0b bl
  %define s1b bpl
  %define s2b r12b
  %define s3b r13b
  %define s4b r14b
  %define s5b r15b
  %define u0q r10
  %define u1q r11
  %define u0d r10d
  %define u1d r11d
  %define u0w r10w
  %define u1w r11w
  %define u0b r10b
  %define u1b r11b
  %endif
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
%ifidn platform, win64
 %macro util_compat_stdc    0
  %define cpt_stdc
  addlib msvcr120.dll
  import _iob,       msvcr120.dll, forced ;Array that contains stdin/out/err
  import _get_errno, msvcr120.dll, forced ;Function to get errno
  %macro geterrno 0
  ccl [_get_errno]
  %endmacro
  %endmacro
 %macro util_compat_cmdl    0
  %define cpt_cmdl
  addlib Kernel32.dll
  addlib msvcr120.dll
  addlib shell32.dll
  import GetCommandLineW,    Kernel32.dll
  import sprintf,            msvcr120.dll
  import CommandLineToArgvW, shell32.dll
  %endmacro
 %macro util_compat_threads 0
  %define cpt_threads
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
  %endmacro
 %macro util_compat_sleep   0
  %define cpt_sleep
  addlib Kernel32.dll
  import Sleep, Kernel32.dll
  %macro sleepms 1
   mov p0d,%1
   ccl [Sleep]
   %endmacro
  %endmacro
 %macro util_compat_time    0
  %define cpt_time
  addlib Kernel32.dll
  import GetTickCount,            Kernel32.dll
  import GetSystemTimeAsFileTime, Kernel32.dll
  %endmacro
 %macro util_compat_sock    0
  %define cpt_sock
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
  %endmacro
 %endif
%ifidn platform, linux
 %macro util_compat_stdc    0
  %define cpt_stdc
  addlib libc.so.6
  import stdin,  x, forced
  import stdout, x, forced
  import stderr, x, forced
  import __errno_location
  %macro geterrno 0
  mov r0q,[c_errptr]
  mov r0q,[r0q]
  %endmacro
  %endmacro
 %macro util_compat_cmdl    0
  %define cpt_cmdl
  %endmacro
 %macro util_compat_threads 0
  %define cpt_threads
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
  %endmacro
 %macro util_compat_sleep   0
  %define cpt_sleep
  addlib libc.so.6
  import usleep
  %macro sleepms 1
   mov p0d,%1*1000
   ccl [usleep]
   %endmacro
  %endmacro
 %macro util_compat_time    0
  %define cpt_time
  addlib libc.so.6
  import gettimeofday
  %endmacro
 %macro util_compat_sock    0
  %define cpt_sock
  addlib libc.so.6
  import close
  %macro sock_init 0
   xor r0d,r0d
   %endmacro
  %macro sock_close 1
   mov p0d,%1
   ccl [close]
   %endmacro
  %endmacro
 %endif
%macro util_compat_all  0
 util_compat_stdc
 util_compat_cmdl
 util_compat_threads
 util_compat_sleep
 util_compat_time
 util_compat_sock
 %endmacro
;Necessary program macros
%ifidn platform, win64
 %macro prog_init 0
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
   argv_gen:
    ;Somewhat hacky solution with reading and writing at the same address and using sprintf instead of WideCharToMultiByte
    ;That said it works fine on my machine
    mov p0q,[s1q]       ;Output to  argv[n]
    lea p1q,[print_cnv] ;Convert the string
    mov p2q,[s1q]       ;Input from argv[n]
    ccl [sprintf]       ;Convert string. UTF8 should always be smaller than LPWSTR
    add s1q,0x08        ;Advance to next pointer
    dec s0d             ;Decrement count
    jnz argv_gen
   %endif
  %endmacro
 %macro fn 2-3
  %if %0 == 3 ;Optional function alignment
   align %3
   %endif
  %1:
  %if %2 == leaf ;Leaf function   / no ABI calls
   %endif
  %if %2 == abic  ;Branch function / makes ABI calls
   sub rsp,0x38
   %endif
  %if %2 == abis ;Safe function   / saves abi preserved registers
   call util_push_abi
   sub rsp,0x38
   %endif
  %if %2 == safe ;Safe function   / saves all registers
   call util_push
   sub rsp,0x40
   %endif
  %endmacro 
 %macro fnr 1
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
  %endmacro
 %macro fn 2-3
  %if %0 == 3 ;Optional function alignment
   align %3
   %endif
  %1:
  %if %2 == leaf ;Leaf function   / no ABI calls
   %endif
  %if %2 == abic ;Branch function / makes ABI calls
   sub rsp,0x08
   %endif
  %if %2 == abis ;Safe function   / saves abi preserved registers
   call util_push_abi
   %endif
  %if %2 == safe ;Safe function   / saves all registers
   call util_push
   %endif
  %endmacro
 %macro fnr 1
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
    push rbx
    push rcx
    mov rcx,[timestamp+0x08]
    mov rax,[timestamp+0x00]
    mov ebx,1000000
    mul rbx
    add rax,rcx
    pop rcx
    pop rbx
    fnr abis
   %endif
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
 %endmacro