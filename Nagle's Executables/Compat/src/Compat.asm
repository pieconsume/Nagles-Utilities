defs:
 %include "../../CompatGen.asm"
 %assign strcnt 0
 %macro debugprint 1-2
  %defstr strdef_%[strcnt] %1
  %if %0 == 1
   lea p0q,[platstr]
   ccl [printf]
   lea p0q,[str_%[strcnt]]
   ccl [printf]
   %endif
  %if %0 == 2
   mov p0q,%2
   lea p1q,[platstr]
   ccl [fprintf]
   mov p0q,%2
   lea p1q,[str_%[strcnt]]
   ccl [fprintf]
   %endif
  %assign strcnt strcnt+1
  %endmacro
imports:
 util_compat_all
 %ifidn platform, win64
  addlib msvcr120.dll
  %endif
 %ifidn platform, linux
  addlib libc.so.6
  %endif
 ;C imports
  import fprintf, msvcr120.dll
  import printf,  msvcr120.dll
  import exit,    msvcr120.dll
  import abort,   msvcr120.dll
 prog_head
code:
 entry:
  prog_init
  debugprint works!
  call test_abic
  call test_abis
  call test_safe
  call test_std
  call test_arg
  thr_test:
   thr_make test_thr,0x1000
   thr_wait:
   cmp dword[thr_done],0x01
   jne thr_wait
  call test_sleep
  call test_time
  call test_sock
  call test_exc
 fn test_abic,  abic
  debugprint ABIC works
  fnr abic
 fn test_abis,  abis
  debugprint ABIS works
  fnr abis
 fn test_safe,  safe
  debugprint SAFE works
  fnr safe
 fn test_std,   abic
  debugprint StdOut works, [c_stdout]
  debugprint StdErr works, [c_stderr]
  fnr abic
 fn test_arg,   abic
  debugprint Printing argc and argv[1]
  mov r0d,[argc]
  call util_printr0d
  mov p0q,[argv]
  mov p0q,[p0q+0x08]
  call [printf]
  lea p0q,[nlstr]
  call [printf]
  fnr abic
 fn test_err,   abic
  fnr abic
 fn test_thr,   abic
  debugprint Threads work
  mov dword[thr_done],0x01
  thr_exit
 fn test_sleep, abic
  debugprint Testing sleepms
  sleepms 200
  fnr abic
 fn test_time,  abic
  debugprint Printing timems and timeus
  call util_timems
  call util_printr0q
  call util_timeus
  call util_printr0q
  fnr abic
 fn test_sock,  abic
  debugprint Printing sock_init result
  sock_init
  call util_printr0d
  fnr abic
 fn test_exc,   abic
  exc_handler test_exch
  mov eax,0
  div eax
  fnr abic
 fn test_exch,  leaf
  and spl,0xF0  ;Better to use a temporary stack in real code
  debugprint Exceptions work
  ccl [exit]
 utilfunc:
  util_func_std
  util_func_compat
 align 0x1000, db 0
 code.end:
data:
 thr_done dd 0
 debugstr:
  %defstr plat platform
  nlstr   db 10,0
  platstr db '[',plat,'] ',0
  %assign idx 0
  %rep strcnt
  str_%[idx] db strdef_%[idx],10,0
  %assign idx idx+1
  %endrep
 utildata:
  util_data_std
  util_data_compat
 align 0x1000, db 0
 data.end:

prog_end