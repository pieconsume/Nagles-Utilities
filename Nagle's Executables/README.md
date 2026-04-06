# Nagle's Executables

 ## ELF
  A mostly finished ELF64 generator supporting imports and imports.

  ```
  Files:
   ELFGen.asm  - contains the macros for generating an ELF64 dynamic executable.
   ELFTest.asm - is an example program using these macros to create a functional program or library.
   LibTest.c   - tests if the generated libELFTest.so can be linked with a regular C program.
  ```

  ```
  Known issues / caveats:
   - GNU_HASH is implemented in a bare-minimum fashion, making symbol searches inefficient.
   - An extra 2 null symbols are added to fix a strange export edgecase bug. I just want to know why.
   - Macros are incomprehensible and don't make use of nasm 3.0 features.
   - Needs tested on more devices. May have obscure compatibility issues.
  ```

 ## PE
  A partially finished PE32+ generator supporting imports and exports.  

  Works on wine. Last year's builds did not run on real windows machines.  

  ```
  Files:
   PEGen.asm  - contains the macros for generating a PE32+ executable or library.
   PETest.asm - is an example program using these macros to create a functional program or library.
   LibTest.c  - tests if the generated libELFTest.so can be linked with a regular C program.
  ```

  ```
  Known issues / caveats:
   - Has not ran on real windows machine since a test years ago. Likely just incorrect header values.
   - Macros are incomprehensible and don't make use of nasm 3.0 features.
  ```

 ## Compat
  Tests all the features of PEGen.asm, ELFGen.asm, and ExeUtils.asm.

  ### The stack does a lot of things (especially on windows) and has to be aligned.
   You have to make sure the stack is just right before calling external functions.  
   This is the reason for the fn and fnr macros, which do all the work for you.  
   
   ```
   fn/fnr types:
   leaf fn  - Does nothing. You cannot call external functions from these.
   abic fn  - Initializes the stack for external C calls.
   abis fn  - Saves s0q-s5q (and h0q-h1q on Windows) then initializes the stack.
   safe fn  - Saves all general purpose registers (except rsp) then initializes the stack.
   ```

  ### Dumpcalls (parameters dumping onto the stack)
   C calls with more than 4 parameters require specific handling due to ABI differences.  
   The headache registers mean that d00-d01 are either dumped onto stack (Windows) or in registers (SystemV).  
   Additionally on Windows stack passed values begin at rsp+0x20, whereas on SystemV they begin at rsp+0x00.  
   To this day I have yet to find an good way to handle these differences. I'm open to suggestions.  
   You can use d00-d31 for some degree of consistency if you can easily deal with the differences.  
   Or use platform specific code to individually handle each case if it gets complicated.  

   TL;DR Keep references to both ABIs handy at all times and be careful with dumpcalls doing odd things.

  ```
  Compatibility registers:
   - s0q-s5q Saved    registers.
   - p0q-p3q Pass     registers.
   - u0q-u1q Unused   registers.
   - h0q-h1q Headache registers. These would be s6q-s7q on Windows and p4q-p5q on SystemV.
   - r0q     Return   register.
   - rsp     Stack    register.
   - d00-d01 Stack dump values. Either h0q-h1q, or on the stack.
   - d02-d31 Stack dump values, always on the stack.
 ```

 ```
 Known issues / caveats:
  - Suffers the same lack of testing of everything I've written, now multiplied by two operating systems.
 ```