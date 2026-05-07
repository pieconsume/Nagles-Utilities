%ifndef platform
 %fatal Platform not specified
 %endif
%ifidn platform, win64
 %include "../../PEGen.asm"
 %endif
%ifidn platform, linux
 %include "../../ELFGen.asm"
 %endif