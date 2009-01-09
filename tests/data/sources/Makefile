all:
	@echo "Please specify OS and architecture (linux-amd64, solaris-x86, ...)"

linux-amd64: linux-amd64-gcc linux-amd64-suncc linux-amd64-icc
linux-amd64-gcc: \
	../linux/amd64/gcc/dynamic_executable.o \
	../linux/amd64/gcc/dynamic_executable \
	../linux/amd64/gcc/static_executable \
	../linux/amd64/gcc/symboltypes.o \
	../linux/amd64/gcc/versioning.so
linux-amd64-suncc: \
	../linux/amd64/suncc/dynamic_executable.o \
	../linux/amd64/suncc/dynamic_executable \
	../linux/amd64/suncc/symboltypes.o
linux-amd64-icc: \
	../linux/amd64/icc/dynamic_executable.o \
	../linux/amd64/icc/dynamic_executable \
	../linux/amd64/icc/static_executable \
	../linux/amd64/icc/symboltypes.o

solaris-x86: solaris-x86-gcc solaris-x86-suncc
solaris-x86-suncc: \
	../solaris/x86/suncc/dynamic_executable.o \
	../solaris/x86/suncc/dynamic_executable \
	../solaris/x86/suncc/symboltypes.o
solaris-x86-gcc: \
	../solaris/x86/gcc/versioning.so \
	../solaris/x86/gcc/dynamic_executable.o \
	../solaris/x86/gcc/dynamic_executable

../%/suncc/dynamic_executable.o: executable.c
	suncc -c executable.c -o $@

../%/suncc/dynamic_executable: executable.c
	suncc executable.c -o $@

../%/suncc/symboltypes.o: symboltypes.c
	suncc -Kpic -D__PIC__ -c symboltypes.c -o $@

../linux/amd64/gcc/dynamic_executable.o: executable.c
	x86_64-pc-linux-gnu-gcc -c executable.c -o $@

../linux/amd64/gcc/dynamic_executable: executable.c
	x86_64-pc-linux-gnu-gcc executable.c -o $@

../linux/amd64/gcc/static_executable: executable.c
	x86_64-pc-linux-gnu-gcc -static executable.c -o $@

../linux/amd64/gcc/symboltypes.o: symboltypes.c
	x86_64-pc-linux-gnu-gcc -fPIC -c symboltypes.c -o $@

../linux/amd64/icc/dynamic_executable.o: executable.c
	icc -c executable.c -o $@

../linux/amd64/icc/dynamic_executable: executable.c
	icc -Wl,--as-needed executable.c -o $@

../linux/amd64/icc/static_executable: executable.c
	icc -static executable.c -o $@

../linux/amd64/icc/symboltypes.o: symboltypes.c
	icc -fPIC -c symboltypes.c -o $@

../linux/amd64/gcc/versioning.so: versioning.c versioning.ld
	x86_64-pc-linux-gnu-gcc -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@

../solaris/x86/gcc/dynamic_executable.o: executable.c
	i386-pc-solaris2.11-gcc -c executable.c -o $@

../solaris/x86/gcc/dynamic_executable: executable.c
	i386-pc-solaris2.11-gcc executable.c -o $@

../solaris/x86/gcc/versioning.so: versioning.c versioning.ld
	i386-pc-solaris2.11-gcc -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@
