# Nagle's Executables

 ## ELF
  A mostly finished ELF64 generator supporting imports and imports.

  Known issues / caveats:
  ```
  - GNU_HASH is implemented in a bare-minimum fashion, making symbol searches inefficient.
  - An extra 2 null symbols are added to fix a strange export edgecase bug. I just want to know why.
  - Macros are incomprehensible and don't make use of nasm 3.0 features.
  - Needs tested on more devices. May have obscure compatibility issues.
  ```

  Files:
  ```
  ELFGen.asm  - contains the macros for generating an ELF64 dynamic executable.
  ELFTest.asm - is an example program using these macros to create a functional program or library.
  LibTest.c   - tests if the generated libELFTest.so can be linked with a regular C program.
  ```

 ## PE
  A partially finished PE32+ generator supporting imports and exports.

  Works on wine last year's builds did not run on real windows machines.

  Known issues / caveats:
  ```
  - Has not ran on real windows machine since a test years ago. Likely just incorrect header values.
  - Macros are incomprehensible and don't make use of nasm 3.0 features.
  ```

  Files:
  ```
  PEGen.asm  - contains the macros for generating a PE32+ executable or library.
  PETest.asm - is an example program using these macros to create a functional program or library.
  LibTest.c  - tests if the generated libELFTest.so can be linked with a regular C program.
  ```

 ## Compat
  Tests all the features of PEGen.asm, ELFGen.asm, and ExeUtils.asm.