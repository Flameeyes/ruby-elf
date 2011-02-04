all:
	@echo "Please specify OS and architecture (linux-amd64, solaris-x86, ...)"

linux-amd64: linux-amd64-gcc linux-amd64-suncc linux-amd64-icc linux-x86
linux-amd64-gcc: \
	../linux/amd64/gcc/dynamic_executable.o \
	../linux/amd64/gcc/dynamic_executable \
	../linux/amd64/gcc/static_executable \
	../linux/amd64/gcc/symboltypes.o \
	../linux/amd64/gcc/versioning.so \
	../linux/amd64/gcc/cxxsymbols.o
linux-amd64-suncc: \
	../linux/amd64/suncc/dynamic_executable.o \
	../linux/amd64/suncc/dynamic_executable \
	../linux/amd64/suncc/symboltypes.o
linux-amd64-icc: \
	../linux/amd64/icc/dynamic_executable.o \
	../linux/amd64/icc/dynamic_executable \
	../linux/amd64/icc/static_executable \
	../linux/amd64/icc/symboltypes.o

linux-x86: \
	../linux/x86/gcc/dynamic_executable.o \
	../linux/x86/gcc/dynamic_executable \
	../linux/x86/gcc/static_executable \

linux-arm: \
	../linux/arm/gcc/dynamic_executable.o \
	../linux/arm/gcc/dynamic_executable \
	../linux/arm/gcc/static_executable \

linux-sparc: \
	../linux/sparc/gcc/dynamic_executable.o \
	../linux/sparc/gcc/dynamic_executable \
	../linux/sparc/gcc/static_executable \

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
	x86_64-pc-linux-gnu-gcc -Wl,-h,versioning.so -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@

../linux/amd64/gcc/cxxsymbols.o: cxxsymbols.c
	x86_64-pc-linux-gnu-g++ -c $< -o $@

../linux/x86/gcc/dynamic_executable.o: executable.c
	x86_64-pc-linux-gnu-gcc -m32 -c executable.c -o $@

../linux/x86/gcc/dynamic_executable: executable.c
	x86_64-pc-linux-gnu-gcc -m32 executable.c -o $@

../linux/x86/gcc/static_executable: executable.c
	x86_64-pc-linux-gnu-gcc -static -m32 executable.c -o $@

../linux/arm/gcc/dynamic_executable.o: executable.c
	arm-linux-gnu-gcc -c executable.c -o $@

../linux/arm/gcc/dynamic_executable: executable.c
	arm-linux-gnu-gcc executable.c -o $@

../linux/arm/gcc/static_executable: executable.c
	arm-linux-gnu-gcc -static executable.c -o $@

../linux/sparc/gcc/dynamic_executable.o: executable.c
	sparc64-linux-gnu-gcc -c executable.c -o $@

../linux/sparc/gcc/dynamic_executable: executable.c
	sparc64-linux-gnu-gcc executable.c -o $@

../linux/sparc/gcc/static_executable: executable.c
	sparc64-linux-gnu-gcc -static executable.c -o $@

../solaris/x86/gcc/dynamic_executable.o: executable.c
	i386-pc-solaris2.11-gcc -c executable.c -o $@

../solaris/x86/gcc/dynamic_executable: executable.c
	i386-pc-solaris2.11-gcc executable.c -o $@

../solaris/x86/gcc/versioning.so: versioning.c versioning.ld
	i386-pc-solaris2.11-gcc -Wl,-h,versioning.so -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@
