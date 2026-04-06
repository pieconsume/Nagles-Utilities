%include "src/ELFGen.asm"

imports:
 addlib libc.so.6
 import printf
 import exit
 export exportTest, testfunc

prog_head

code:
 entry:
  prog_init
  lea p0q,[test0]
  ccl [printf]
  ccl [exit]
 fn testfunc, abic
  lea p0q,[test1]
  ccl [printf]
  fnr abic
 code.end:
 align 0x1000, db 0 ;Page align
data:
 test0 db 'ELF works!',10,0
 test1 db 'ELF exports work!',10,0
 data.end:
 align 0x1000, db 0 ;Page align

prog_end