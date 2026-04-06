%ifidn platform, win64
 %include "../../PEGen.asm"
 %endif
%ifidn platform, linux
 %include "../../ELFGen.asm"
 %endif
