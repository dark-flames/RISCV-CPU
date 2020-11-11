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
OBJS	= target/startup.o target/sort.o
START_UP = target/startup.o
SRC = tests/test_bench.v src/*.v src/Modules/*.v
TESTCASE_PATH = tests/sort.c

all: riscv testcase

riscv:
	iverilog $(SRC) -o target/riscv

testcase: target/sort.mif target/sort.verilog target/sort.lst

vcd: target/riscv.vcd

target/sort.mif: target/sort.verilog
	tests/vlogdump2mif.py target/sort.verilog -s

target/sort.verilog: target/sort.elf
	$(OBJ_COPY) -O verilog  $< $@

target/sort.lst: target/sort.elf
	$(OBJ_DUMP) -D $< > $@

target/sort.elf: $(OBJS)
	$(LD) $(LD_FLAGS) -o $@ $(OBJS)

target/startup.o:
	$(AS) $(AS_FLAGS) -o $(START_UP) tests/startup.s

target/sort.o:
	$(CC) $(C_FLAGS) -c -o target/sort.o $(TESTCASE_PATH)

target/riscv.vcd: target/riscv target/sort_data.mif target/sort_prog.mif
	vvp -n target/riscv > target/result.txt

clean:
	$(RM) *~ target/* *.log