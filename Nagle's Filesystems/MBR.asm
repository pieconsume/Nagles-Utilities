;Defs
 [BITS 16]
 [DEFAULT ABS]
 [ORG 0x7C00]
entry:
 mov edi,noboot
 mov ecx,noboot.end-noboot
 print_loop:
  mov ah,0x0E
  mov al,[edi]
  test al,al
  jz done
  xor bh, bh
  int 0x10
  inc edi
  loop print_loop
  done:
  cli
  hlt
 noboot db "This is a partition created by Nagle's Fat32 Generator",0
 noboot.end:
pmbr:
 times 0x1B8-($-$$) db 0
 dd 0x51B73312     ;0x1B8 Signature
 dw 0              ;0x1BC Copy protect (ignore)
 ;Partition 0
 db 0x80           ;0x1BE Status, bootable
 db 0,0x20,0       ;0x1BF Starting CHS
 db 0xEE           ;0x1C2 Partition type (PMBR)
 db 0xFF,0xFF,0xFF ;0x1C3 Ending CHS
 dd 0x1            ;0x1C6 Starting LBA
 dd 0xFFFFFFFF     ;0x1CA Length in sectors, should be ignored
 times 6 dq 0      ;0x1CE Partitions 2-4
 dw 0xAA55         ;0x1FE Boot identifier