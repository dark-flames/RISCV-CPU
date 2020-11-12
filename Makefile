CROSS_COMPILE=/opt/riscv32/bin/riscv32-unknown-elf-
#CROSS_COMPILE=/opt/riscv/bin/riscv32-unknown-elf-
CC     = $(CROSS_COMPILE)gcc
AS     = $(CROSS_COMPILE)as
LD     = $(CROSS_COMPILE)ld
OBJ_COPY= $(CROSS_COMPILE)objcopy
OBJ_DUMP= $(CROSS_COMPILE)objdump

C_FLAGS  = -O -march=rv32i -ffreestanding
AS_FLAGS = --gstabs+ -march=rv32i
LD_FLAGS = -nostartfiles --no-relax -Bstatic -T tests/link.ld -nostdlib
OBJS	= target/startup.o target/${PROGRAM}.o
START_UP = target/startup.o
SRC = tests/test_bench.v src/*.v src/Modules/*.v

all: testcase riscv

riscv:
	iverilog $(SRC) -o target/riscv

testcase: target/${PROGRAM}.mif target/${PROGRAM}.verilog target/${PROGRAM}.lst

vcd: target/riscv.vcd

gtkwave: target/riscv.vcd
	gtkwave target/riscv.vcd

target/${PROGRAM}.mif: target/${PROGRAM}.verilog
	tests/vlogdump2mif.py target/${PROGRAM}.verilog -s
	mv data.mif target/data.mif
	mv prog.mif target/prog.mif

target/${PROGRAM}.verilog: target/${PROGRAM}.elf
	$(OBJ_COPY) -O verilog  $< $@

target/${PROGRAM}.lst: target/${PROGRAM}.elf
	$(OBJ_DUMP) -D $< > $@

target/${PROGRAM}.elf: $(OBJS)
	$(LD) $(LD_FLAGS) -o $@ $(OBJS)

target/startup.o:
	$(AS) $(AS_FLAGS) tests/startup.s -o $(START_UP)

target/${PROGRAM}.o:
	$(CC) $(C_FLAGS) -c -o target/${PROGRAM}.o tests/${PROGRAM}.c

target/riscv.vcd: target/riscv target/data.mif target/prog.mif
	vvp -n target/riscv > target/result.txt


.PHONY: clean
clean:
	$(RM) *~ target/* *.log