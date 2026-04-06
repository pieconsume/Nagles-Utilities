%include "src/PEGen.asm"

imports:
 addlib msvcr120
 import printf, msvcr120
 import strlen, msvcr120
 import exit  , msvcr120
 export exportTest, testfunc

prog_head

code:
 entry:
  %ifdef dll
  ret
  %else
  prog_init
  lea p0q,[test0]
  ccl [printf]
  ccl [exit]
  %endif
 fn testfunc, abic
  lea p0q,[test1]
  ccl [printf]
  fnr abic
 code.end:
 align 0x1000, db 0 ;Page align
data:
 test0 db 'PE works!', 10, 0
 test1 db 'PE exports work!', 10, 0
 data.end:
 align 0x1000, db 0 ;Page align

prog_end