ASM=nasm
CC=g++
# -masm=intel
FLAGS=-std=c++20 -O1 -Wno-error -c -nostdinc -nostdlib -fno-builtin -fno-stack-protector -ffreestanding -m32
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
.PHONY: all_bin

build: clean all_bin
	cat bin/boot.bin bin/second_stage.bin bin/kernel.bin > bin/OS.img
#@cat $(BIN) > bin/OS.img

run: build
	@qemu-system-i386 -m 4G -drive format=raw,file=$(IMG),if=ide,index=0,media=disk

clean:
	@rm -rf bin/*.bin 
	@rm -rf bin/*.o
	@rm -rf $(IMG)

bin/boot.bin:
	@echo "Assembling \e[0;96m" $(ASM_DIR)boot.asm "\e[0;37m -> \e[0;96mbin/boot.bin\e[0;37m"
	@$(ASM) $(ASM_DIR)boot.asm -f elf32 -o bin/boot.bin
	@ld -m elf_i386 -T$(LD_DIR)boot.ld -nostdlib -o bin/boot.out bin/boot.bin
	@objcopy -O binary bin/boot.out bin/boot.bin

bin/second_stage.bin:
	@echo "Assembling \e[0;96m" $(ASM_DIR)second_stage.bin "\e[0;37m -> \e[0;96mbin/second_stage.bin\e[0;37m"
	@$(ASM) $(ASM_DIR)second_stage.asm -f elf32 -o bin/second_stage.bin
	@ld -m elf_i386 -T$(LD_DIR)second_stage.ld -nostdlib -o bin/second_stage.out bin/second_stage.bin	
	@objcopy -O binary bin/second_stage.out bin/second_stage.bin

bin/kernel.bin:
	@$(CC) $(FLAGS) -Iinclude/ kernel.c -o bin/kernel.o
	@ld -m elf_i386 -T$(LD_DIR)kernel.ld -nostdlib --nmagic -o bin/kernel.out bin/kernel.o
	@objcopy -O binary bin/kernel.out bin/kernel.bin
	@./format.o

all_bin: bin/boot.bin bin/second_stage.bin bin/kernel.bin
