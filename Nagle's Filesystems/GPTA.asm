;WARNING - Macro black magic used for 2-pass CRC generation

%define crcgen                ;Only generate the CRC when including
%include "../GPTE.asm" ;Process the GPTE CRC

getrand gpt_guid0
getrand gpt_guid1
crc_mke gpt_crc

pass_rst

crc_dq gpt_crc, 0x5452415020494645 ;0x00 Signature
crc_dd gpt_crc, 0x10000            ;0x08 Version 1.0 (UEFI 2.9 and below)
crc_dd gpt_crc, 0x0000005C         ;0x0C Header size, 92
crc_ad gpt_crc, 0                  ;0x10 Accumlate 0 for the CRC value
p2op   dd       gpt_crc            ;0x10 CRC
crc_dd gpt_crc, 0                  ;0x14 Reserved
crc_dq gpt_crc, 0x0000000000000001 ;0x18 Current LBA
crc_dq gpt_crc, disksects-0x01     ;0x20 Backup LBA
crc_dq gpt_crc, 0x000000000000000A ;0x28 First usuable LBA (Current LBA + full GPT size)
crc_dq gpt_crc, disksects-0x09     ;0x30 Last usuable LBA  (Last sector - (GPT header + partition entry array))
crc_dq gpt_crc, gpt_guid0          ;0x38 GUID
crc_dq gpt_crc, gpt_guid1          ;0x40 GUID
crc_dq gpt_crc, 0x0000000000000002 ;0x48 Partition entry array LBA
crc_dd gpt_crc, 0x20*(secsz/0x200) ;0x50 Number of partition entries (8 sectors worth)
crc_dd gpt_crc, 0x00000080         ;0x54 Partition entry size (128)
crc_dd gpt_crc, gpte_crc           ;0x58 Partition entry array CRC

crc_fin gpt_crc
pass_fin