../linux/amd64/gcc/versioning.so: versioning.c versioning.ld
	x86_64-pc-linux-gnu-gcc -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@

../solaris/x86/gcc/versioning.so: versioning.c versioning.ld
	i386-pc-solaris2.11-gcc -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@
