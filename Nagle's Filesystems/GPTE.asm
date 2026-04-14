;WARNING - Macro black magic used for 2-pass CRC generation

%include "../FSUtils.asm"

getrand ent_guid0
getrand ent_guid1
crc_mke gpte_crc

;Note - This is an EFI System Partition
crc_dq gpte_crc, 0x11D2F81FC12A7328 ;0x00 Type GUID
crc_dq gpte_crc, 0x3BC93EC9A0004BBA ;0x08 Type GUID
crc_dq gpte_crc, ent_guid0          ;0x10 Partition GUID
crc_dq gpte_crc, ent_guid1          ;0x18 Partition GUID
crc_dq gpte_crc, 0x000000000000000A ;0x20 Starting LBA
crc_dq gpte_crc, 0x0A+partsz        ;0x28 Ending LBA
crc_dq gpte_crc, 0x8000000000000000 ;0x30 Attributes
crc_dw gpte_crc, 0x0054             ;0x38 T
crc_dw gpte_crc, 0x0045             ;0x3A E
crc_dw gpte_crc, 0x0053             ;0x3C S
crc_dw gpte_crc, 0x0054             ;0x3E T
%rep 0x40
crc_db gpte_crc, 0x00
%endrep

%rep (0x08*secsz)-(0x80*1)
crc_db gpte_crc, 0x00
%endrep

crc_fin gpte_crc

%ifndef crcgen
 pass_fin
 %endif