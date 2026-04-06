# Nagle's Utilities
 The current scope of the project is to generate various doodads using nasm's powerful sorcery (macros).  
 However eventually (once the executable generators are stable) I plan to write some asm versions.  
 So first a version to maximize transparency in how something works at a binary level.  
 Then a more practical command line tool to do effectively the same thing.  

 ## Nagle's Executables
  Magically (nasm macro) generated ELF and PE executable files.  
  Navigate for more details.

 ## Nagle's Filesystems
  Magically (nasm macro) generated filesystems.  
  Navigate for more details.

 ## Nagle's Media
  Magically (nasm macro) generated media files.  
  Navigate for more details.

 ## Macro files
  ```
  GenericUtils.asm - Generic utility macros such as error printing, random numbers, and checksum/crc32 generation.
  ExeUtils.asm     - Exectuable file specific macros for cross-platform compatibility.
  ELFGen.asm       - Copied from Nagle's Executables.
  PEGen.asm        - Copied from Nagle's Executables.
  CompatGen.asm    - Switch for ELFGen/PEGen based on input flags.
  ```

  ### GenericUtils
   Generic utilities used almost globally across subprojects.  
   ```
   Features:
    - A debug print function (hexprint).
    - Utility and math defines like exp(x), sz(x), and roundu/d(x).
    - Xorshift random number generator with __?POSIX_TIME?__ as its seed.
    - Checksum 2-pass accumulator.
    - CRC32 2-pass accumlator (proud of this one).
   ```

  ### ExeUtils
   Cross-platform windows and linux compatibility macros used by any executable in the project.  
   ```
   Features:
    - Abstracted C ABI registers (p0q, s0q, r0q, u0q).
    - Conditional import call/mov (ccl, cmv). WIP.
    - Abstracted C ABI program entry, call, and return (prog_init, fn, fnr).
    - Compatibility packages for common features
    - Misc utility functions I like to use
   ```

   ```
   Compatibility packages:  
    util_compat_stdc    - Gets      stdin/out/err, errno.
    util_compat_cmdl    - Gets      argc, argv.
    util_compat_threads - Macros    thr_make, thr_exit
    util_compat_sleep   - Macros    sleepms
    util_compat_time    - Functions util_timems, util_timeus
    util_compat_sock    - Macros    sock_init, sock_close
    util_compat_excs    - Macros    exc_handler
   ```