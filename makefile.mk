ASM=nasm
ASMFLAGS=-g -felf64
LD=ld
LDFLAGS=-o
ALLOBJECTFILES=lib.o float_lib.o float_calc.o

.PHONY: clean all

all: float_calc $(ALLOBJECTFILES) clean

clean:
	rm -rf *.o temp

lib.o: lib.asm
	$(ASM) $(ASMFLAGS) $< $(LDFLAGS) $@

float_lib.o: float_lib.asm
	$(ASM) $(ASMFLAGS) $< $(LDFLAGS) $@

float_calc.o: float_calc.asm float_lib.o lib.o float_lib.inc lib.inc 
	$(ASM) $(ASMFLAGS) $< $(LDFLAGS) $@

float_calc: $(ALLOBJECTFILES)
	$(LD) $(LDFLAGS) $@ $(ALLOBJECTFILES)

