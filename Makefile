
BUILD_DIR ?= build

.SECONDEXPANSION:

# marker file to create when making directory
MARKER_FILE := .marker

# Marker prereq
MARKER = $$(@D)/$(MARKER_FILE)

%/$(MARKER_FILE):
	mkdir -p $(dir $@)
	@touch $@

.PRECIOUS: %/$(MARKER_FILE)

COBJS	= 	stage2/main.o \
			stage2/ext2.o \
			stage2/lib.o \
			stage2/vga.o \
			stage2/elf.o
COBJS := $(addprefix $(BUILD_DIR)/,$(COBJS))

STAGE1 := $(BUILD_DIR)/stage1.bin
STAGE2 := $(BUILD_DIR)/stage2.bin

CC	    = i686-elf-gcc
LD		= i686-elf-ld
AS		= nasm

CCFLAGS	= -w -fno-pic -fno-builtin -nostdlib -ffreestanding -std=gnu99 -m32 -c 
EXT2UTIL= ../ext2util/ext2util

DISK	= $(BUILD_DIR)/boot.img


all: compile clean
run: kernel compile clean emu
nok: compile clean emu


$(BUILD_DIR)/%.o : %.c $(MARKER)
	$(CC) $(CCFLAGS) $< -o $@



stage1: $(STAGE1)

$(STAGE1): bootstrap.asm $(MARKER)
	$(AS) -f bin $< -o $@

stage2: $(STAGE2)

$(STAGE2): $(COBJS) $(MARKER)
	$(LD) -N -e stage2_main -Ttext 0x00050000 -o $@ $(COBJS) --oformat binary



kernel:
	make -C ../crunchy

# compile: $(BOOTIMG)
# 	$(AS) -f bin bootstrap.asm -o stage1.bin

# 	$(LD) -N -e stage2_main -Ttext 0x00050000 -o stage2.bin $(COBJS) --oformat binary

# 	cp boot.img.bak boot.img
# 	dd if=stage1.bin of=$(DISK) conv=notrunc

# 	#cp ../crunchy/bin/kernel.bin ./kernel

# 	$(EXT2UTIL) -x $(DISK) -wf stage2.bin -i 5
# 	$(EXT2UTIL) -x $(DISK) -wf kernel
# 	$(EXT2UTIL) -x $(DISK) -wf boot.conf

compile: $(STAGE1) $(STAGE2) $(DISK)
	dd if=$(STAGE1) of=$(DISK) conv=notrunc
	$(EXT2UTIL) -x $(DISK) -wf $(STAGE2) -i 5
	$(EXT2UTIL) -x $(DISK) -wf boot.conf

$(DISK) new:
	dd if=/dev/zero of=$(DISK) bs=1k count=16k
	mke2fs $(DISK)

emu: 
	qemu-system-i386 -hdb $(DISK) -curses

clean:

	rm stage2/*.o
