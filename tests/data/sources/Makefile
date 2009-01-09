all:
	@echo "Please specify OS and architecture (linux-amd64, solaris-x86, ...)"

linux-amd64: linux-amd64-gcc linux-amd64-suncc linux-amd64-icc
linux-amd64-gcc: ../linux/amd64/gcc/symboltypes.o ../linux/amd64/gcc/versioning.so
linux-amd64-suncc: ../linux/amd64/suncc/symboltypes.o
linux-amd64-icc: ../linux/amd64/icc/symboltypes.o

solaris-x86: solaris-x86-gcc
solaris-x86-gcc: ../solaris/x86/gcc/versioning.so ../solaris/x86/suncc/symboltypes.o

../linux/amd64/gcc/symboltypes.o: symboltypes.c
	x86_64-pc-linux-gnu-gcc -fPIC -c symboltypes.c -o $@

../linux/amd64/suncc/symboltypes.o: symboltypes.c
	suncc -Kpic -D__PIC__ -c symboltypes.c -o $@

../linux/amd64/icc/symboltypes.o: symboltypes.c
	icc -fPIC -c symboltypes.c -o $@

../linux/amd64/gcc/versioning.so: versioning.c versioning.ld
	x86_64-pc-linux-gnu-gcc -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@

../solaris/x86/suncc/symboltypes.o: symboltypes.c
	suncc -Kpic -D__PIC__ -c symboltypes.c -o $@

../solaris/x86/gcc/versioning.so: versioning.c versioning.ld
	i386-pc-solaris2.11-gcc -shared -fPIC versioning.c -Wl,--version-script=versioning.ld -o $@
