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
  ;lea p0q,[test0]
  ;ccl [printf]
  xor s0d,s0d
  chkloop:
   mov p0d,s0d
   call tempfunc
   test r0d,r0d
   jz chkloop_next
   lea p0q,[temp0]
   mov p1d,s0d
   mov p2d,r0d
   call [printf]
   chkloop_next:
   inc s0d
   cmp s0d,32
   jl chkloop
  ccl [exit]
 fn testfunc, abic
  lea p0q,[test1]
  ccl [printf]
  fnr abic
 fn tempfunc, leaf
  ;value in p0d
  xor   r0d,r0d
  mov   p1d,0x8122 ;Bit mask
  bt    p1d,p0d
  setc  r0b
  fnr leaf
 code.end:
 align 0x1000, db 0 ;Page align
data:
 test0 db 'ELF works!',10,0
 test1 db 'ELF exports work!',10,0
 temp0 db 'Match: [0x%02X]',10,0
 data.end:
 align 0x1000, db 0 ;Page align

prog_end