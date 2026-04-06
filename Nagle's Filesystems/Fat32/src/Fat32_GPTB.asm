;WARNING - Macro black magic used for 2-pass CRC generation

%define crcgen
%include "src/Fat32_GPTE.asm"

getrand gptb_guid0
getrand gptb_guid1
crc_mke gptb_crc
pass_rst

crc_dq gptb_crc, 0x5452415020494645 ;0x00 Signature
crc_dd gptb_crc, 0x10000            ;0x08 Version 1.0 (UEFI 2.9 and below)
crc_dd gptb_crc, 0x0000005C         ;0x0C Header size, 92
crc_ad	gptb_crc, 0                  ;0x10 Accumlate 0 for the CRC value
p2op   dd        gptb_crc           ;0x10 CRC
crc_dd gptb_crc, 0                  ;0x14 Reserved
crc_dq gptb_crc, disksects-0x01     ;0x20 Current LBA
crc_dq gptb_crc, 0x0000000000000001 ;0x18 Main LBA
crc_dq gptb_crc, 0x000000000000000A ;0x28 First usuable LBA (Current LBA + full GPT size)
crc_dq gptb_crc, disksects-0x09     ;0x30 Last usuable LBA  (Last sector - (GPT header + partition entry array))
crc_dq gptb_crc, gptb_guid0         ;0x38 GUID
crc_dq gptb_crc, gptb_guid1         ;0x40 GUID
crc_dq gptb_crc, 0x0000000000000002 ;0x48 Partition entry array LBA
crc_dd gptb_crc, 0x20*(secsz/0x200) ;0x50 Number of partition entries (8 sectors worth)
crc_dd gptb_crc, 0x00000080         ;0x54 Partition entry size (128)
crc_dd gptb_crc, gpte_crc           ;0x58 Partition entry array CRC
;Note - Padded in Fat32_FS.asm to avoid CRC issues

crc_fin gptb_crc
pass_fin