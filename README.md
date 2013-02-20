Ruby-Elf
========

[![Flattr this!](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/thing/27866/Ruby-Elf)

Ruby-Elf is a pure-Ruby library for parse and fetch information about
ELF format used by Linux, FreeBSD, Solaris and other Unix-like
operating systems, and include a set of analysis tools helpful for
both optimisations and verification of compiled ELF files.

The library allows access to all the details of the ELF files (class,
type, architecture OS), and also implements Ruby-style access to the
most important sections in ELF files, such as symbol and string
tables, as well as dynamic information. Furthermore it implements
support for accessing extensions specifics for instance to the GNU
loader such as symbol version information.

Tools
-----

To complement the library raw access, the project also ships with a
number of tools, designed to analyse compiled code, in either
relocated object or final (executable or shared object) form. These
include both optimisation and verification tools:

 * `cowstats`: allows identification and assessment of CoW data
   objects inside ELF relocatable files. Should be used to reduce the
   memory impact of a shared library used by many processes on the
   system.

 * `rbelf-size`: implements an alternative approach for the size
   command available on standard Unix systems (as provided by binutils
   or elfutils packages in most Linux distributions), that focus more
   on relocation caused by PIC than the actual shared memory sizes.

 * `rbelf-nm`: implements a quasi-compatible `nm(1)` command, more
   resilient than GNU `nm` and more informative than the elfutils
   variant.
 
 * `verify-lfs`: checks executables and shared objects, or
   alternatively relocatable object files, for LFS compliancy,
   reporting those that don't make use of the largefile-compatible
   interfaces or that mix old and new ones.
 
 * `elfgrep`: looks for defined or required symbols in dynamic
   executables and shared objects, with a command syntax similar to
   the standard `grep` tool.
   
License
-------

Due to derivation, library and tools are released under the GNU GPL-2
license, or later. See the [`COPYING`](COPYING) file for the complete
text.

Resources
---------

You can find the source code for the package at
[GitHub](https://github.com/Flameeyes/ruby-elf) — previously at
[Gitorious](https://gitorious.org/ruby-elf).

Development and file releases are on
[Rubyforge](http://rubyforge.org/projects/ruby-elf/).
