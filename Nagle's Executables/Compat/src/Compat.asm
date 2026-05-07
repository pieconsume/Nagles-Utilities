;Todo - switch to context local defines

defs:
 %include "../../CompatGen.asm"
 %assign strcnt 0
 %macro debugprint 1
  %ifnstr %1
   %defstr strdef_%[strcnt] %1
  %else
   %define strdef_%[strcnt] %1
   %endif
  lea p0q,[str_%[strcnt]]
  lea p1q,[platstr]
  ccl [printf]
  %assign strcnt strcnt+1
  %endmacro
imports:
 util_compat_all
 %define pf_allfuncs
 %define dbg_allfuncs
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
 fn entry,      prog, 0x10, line
  debugprint "works!"
  call test_abic
  call test_abis
  call test_safe
  call test_exci
  call test_map
  call test_std
  call test_arg
  call test_thrmk
  call test_sleep
  call test_time
  call test_sock
  call test_dbg
  call test_pf
  call test_exc
 fn test_abic,  abic, 0x10, line
  debugprint "ABIC works"
  fnr abic
 fn test_abis,  abis, 0x10, line
  debugprint "ABIS works"
  fnr abis
 fn test_safe,  safe, 0x10, line
  debugprint "SAFE works"
  fnr safe
 fn test_exci,  abic, 0x10, line
  exc_handler test_exch
  fnr abic
 fn test_map,   abic, 0x10, line
  debugprint "Program map: "
  ml lea p2q,[img]  : lea p3q,[img.end]  : debugprint " Image: [0x%016llX-0x%016llX]"
  ml lea p2q,[code] : lea p3q,[code.end] : debugprint " Code:  [0x%016llX-0x%016llX]"
  ml lea p2q,[data] : lea p3q,[data.end] : debugprint " Data:  [0x%016llX-0x%016llX]"
  ml lea p2q,[bss]  : lea p3q,[bss.end]  : debugprint " Bss:   [0x%016llX-0x%016llX]"
  ml lea p2q,[stk]  : lea p3q,[stk.end]  : debugprint " Stack: [0x%016llX-0x%016llX]"
  fnr abic
 fn test_std,   abic, 0x10, line
  ml mov p0q,[c_stdout] : lea p1q,[stdoutstr] : lea p2q,[platstr] : ccl [fprintf]
  ml mov p0q,[c_stderr] : lea p1q,[stderrstr] : lea p2q,[platstr] : ccl [fprintf]
  fnr abic
 fn test_arg,   abic, 0x10, line
  mov p2d,[argc]                  ;Get argc
  debugprint "Check argc:    %i"  ;Wrt argc
  mov p2q,[argv]                  ;Get argv
  mov p2q,[p2q+0x08]              ;Get argv[1]
  debugprint "Check argv[1]: %s"  ;Wrt argv[1]
  fnr abic
 fn test_err,   abic, 0x10, line
  fnr abic
 fn test_thrmk, abic, 0x08, line
  thr_make test_thr,0x1000
  thr_wait:
  cmp dword[thr_done],0x01
  jne thr_wait
  fnr abic
 fn test_thr,   abic, 0x10, line
  debugprint "Threads work"
  mov dword[thr_done],0x01
  thr_exit
 fn test_sleep, abic, 0x10, line
  debugprint "Testing sleepms"
  sleepms 200
  fnr abic
 fn test_time,  abic, 0x10, line
  ml call util_timems : mov p2q,r0q : debugprint "Testing util_timems: 0x%016llX"
  ml call util_timeus : mov p2q,r0q : debugprint "Testing util_timeus: 0x%016llX"
  fnr abic
 fn test_sock,  abic, 0x10, line
  sock_init
  mov p2q,r0q
  debugprint "Testing sock_init:   0x%016llX"
  fnr abic
 fn test_dbg,   abic, 0x10, line
  debugprint "Printing debug info"
  call util_dbg_printall
  fnr abic
 fn test_pf,    abic, 0x10, line
  debugprint "Printing profiling data"
  pf_wa
  fnr abic
 fn test_exc,   abic, 0x10, line
  mov eax,0
  div eax
  fnr abic
 fn test_exch,  leaf, 0x10, line
  %define idx 0
  %rep 0x10
   mov [dbg_frame+(idx*0x08)],auto%[idx]q
   %assign idx idx+1
   %endrep
  lea rsp,[bss.end-0x10]
  debugprint "Register dump:"
  %define idx 0
  %rep 0x10
   ml mov p2q,[dbg_frame+(idx*8)] : debugprint [0x%[%]016llX] [auto%[idx]q]
   %assign idx idx+1
   %endrep
  test_exc_nostk:
  ccl [exit]
 utilfunc:
  util_func_std
  util_func_compat
 align 0x1000, db 0
 code.end:
data:
 dbg_frame times 0x10 dq 0
 rsptest dq 0
 thr_done dd 0
 debugstr:
  %defstr plat platform
  nlstr   db 10,0
  platstr db '[',plat,'] ',0
  stdoutstr db '%sStdOut works',10,0
  stderrstr db '%sStdErr works',10,0
  %assign idx 0
  %rep strcnt
  str_%[idx] db "%s",strdef_%[idx],10,0
  %assign idx idx+1
  %endrep
 utildata:
  util_data_std
  util_data_compat
 align 0x1000, db 0
 data.end:

prog_end