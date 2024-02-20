ASM=nasm
CC=g++
# -masm=intel
FLAGS=-std=c++20 -masm=intel -O1 -Wno-error -c -nostdinc -nostdlib -fno-builtin -fno-stack-protector -ffreestanding -m32
IMG=bin/OS.img
BIN=$(wildcard bin/*.bin)
ASM_DIR=boot/
LD_DIR=linker/

# General commands for the Makefile
.PHONY: build
.PHONY: run

# Cleaning `bin/` directory, including the `OS.img` file
.PHONY: clean

# For `build`
.PHONY: bin/boot.bin
.PHONY: bin/second_stage.bin
.PHONY: bin/kernel.bin
.PHONY: bin/pre_kernel.bin
.PHONY: all_bin

build: clean all_bin
	cat bin/boot.bin bin/second_stage.bin bin/pre_kernel.bin bin/kernel.bin > bin/OS.img
#@cat $(BIN) > bin/OS.img

run: build
	@qemu-system-i386 -debugcon stdio -m 4G -drive format=raw,file=$(IMG),if=ide,index=0,media=disk
run-bochs: build
	@bochs

clean:
	@rm -rf bin/*.bin 
	@rm -rf bin/*.o
	@rm -rf $(IMG)

bin/boot.bin:
	@echo "Assembling \e[0;96m" $(ASM_DIR)boot.asm "\e[0;97m -> \e[0;96mbin/boot.bin\e[0;97m"
	@$(ASM) $(ASM_DIR)boot.asm -f elf32 -o bin/boot.bin
	@echo "\tLinking \e[0;96mbin/boot.bin\e[0;97m ("$(LD_DIR)"boot.ld) -> \e[0;96mbin/boot.out\e[0;97m"
	@ld -m elf_i386 -T$(LD_DIR)boot.ld -nostdlib -o bin/boot.out bin/boot.bin
	@echo "\tConverting \e[0;96mbin/boot.out\e[0;97m to flat binary (objcopy -O binary) -> \e[0;96mbin/boot.bin\e[0;97m\n"
	@objcopy -O binary bin/boot.out bin/boot.bin

bin/second_stage.bin:
	#@$(CC) $(FLAGS) -Iinclude/ test.c -o bin/test.o
	@echo "Assembling \e[0;96m" $(ASM_DIR)second_stage.bin "\e[0;97m -> \e[0;96mbin/second_stage.bin\e[0;97m"
	@$(ASM) $(ASM_DIR)second_stage.asm -f elf32 -o bin/second_stage.bin
	@echo "\tLinking \e[0;96mbin/second_stage.bin\e[0;97m ("$(LD_DIR)"second_stage.ld) -> \e[0;96mbin/second_stage.out\e[0;97m"
	@ld -m elf_i386 -T$(LD_DIR)second_stage.ld -nostdlib -o bin/second_stage.out bin/second_stage.bin
#bin/test.o u.o
	@echo "\tConverting \e[0;96mbin/second_stage.out\e[0;97m to flat binary (objcopy -O binary) -> \e[0;96mbin/second_stage.bin\e[0;97m\n"
	@objcopy -O binary bin/second_stage.out bin/second_stage.bin

bin/pre_kernel.bin:
	@nasm boot/util/util.asm -f elf32 -o bin/util.o
	@$(CC) $(FLAGS) -I include/ pre_kernel.c -o bin/pre_kernel.o
	@ld -m elf_i386 -T$(LD_DIR)pre_kernel.ld -nostdlib --nmagic -o bin/pre_kernel.out bin/pre_kernel.o bin/util.o
	@objcopy -O binary bin/pre_kernel.out bin/pre_kernel.bin
	@./format.o bin/pre_kernel.bin

bin/kernel.bin:
	@echo "Compiling \e[0;96mkernel.c\e[0;97m (g++" $(FLAGS)") -> \e[0;96mbin/kernel.o\e[0;97m"
#@gcc $(FLAGS) -c -o bin/kernel.o kernel.c 
	@$(CC) $(FLAGS) -Iinclude/ kernel.c -o bin/kernel.o 
#@$(CC) $(FLAGS) -o bin/kernel.o u.o kernel.c
	@echo "\tLinking \e[0;96mbin/kernel.o\e[0;97m ("$(LD_DIR)"kernel.ld) -> \e[0;96mbin/kernel.out\e[0;97m"
	@ld -m elf_i386 -T$(LD_DIR)kernel.ld -nostdlib --nmagic -o bin/kernel.out bin/kernel.o bin/util.o
	@echo "\tConverting \e[0;96mbin/kernel.out\e[0;97m to flat binary (objcopy -O binary) -> \3[0;96mbin/kernel.bin\e[0;97m"
	@objcopy -O binary bin/kernel.out bin/kernel.bin
	@echo "\tFormatting \e[0;96mbin/kernel.bin\e[0;97m to multiple of 512 bytes (./format.o) -> \e[0;96mbin/kernel.bin\e[0;97m\n"
	@./format.o bin/kernel.bin

all_bin: bin/boot.bin bin/second_stage.bin bin/pre_kernel.bin bin/kernel.bin
