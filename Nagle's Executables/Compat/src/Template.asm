defs:
 %include "../../CompatGen.asm"
imports:
 util_compat_exc
 util_compat_dbg
 util_compat_section bss, 0x1000
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
 prog_head
code:
 %define platstr "[",%str(platform),"] "
 fn entry,  prog, 0x10, line, nopf
  dbg_printf platstr,"Template works",10,0
  exc_handler on_exc
  ccl [exit]
 fn on_exc, leaf, 0x10, line, nopf
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
 utildata:
  util_data_std
  util_data_compat
 align 0x1000, db 0
 data.end:
prog_end