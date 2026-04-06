# Nagle's Filesystems

 ## Ext2
  A generator for a minimal (only base features) ext2 filesystem.

  ```
  Known issues / caveats:
   - Only tested on one machine. No issues were reported by standard tools, but it may still have obscure compatibility issues.
   - Settings are hardcoded instead of passed by command line.
   - Macros are incomprehensible and don't make use of nasm 3.0 features.
  ```

 # Ext4
  A generator intended to eventually support all ext4 features.  
  Currently just some formatted hexdumps of example ext4 filesystems.  

  ```
  Known issues / caveats:
   - Doesn't do anything.
  ```

 # Fat32
  A generator for a FAT32 filesystem.

  ```
  Options:
   secsz     - Sector size in bytes.
   disksects - Disk sectors.
   fatsecs   - FAT  sectors.
   fatspc    - FAT  sectors per cluster.
  ```

  ```
  Known issues / caveats:
   - File sizes must be obtained by the run script and passed to the file. This is fixable but I haven't gotten around to it.
   - Doesn't support LFNs. This may be added in the future.
   - Option defines should have better names.
   - Macros are surprisingly comprehensible, but don't make use of nasm 3.0 features.
  ```

 # NTFS
  Not started. Don't expect anything anytime soon.

 # GUID partitions
  A GUID partition table is currently only added to FAT32.  
  I plan to add it as a toggle for any filesystem using a single set of source files in the upper directory.  
  Fairly easy to do but I haven't gotten around to it yet.  