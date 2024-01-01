PROJECT = screensaver
SRC = "$(PROJECT).asm"

AS = nasm
QEMU = qemu-system-i386

QEMU_FLAGS = -drive format=raw,index=0,media=disk,file="$(PROJECT).img"

default: 	build

build:		build_img check_size

build_img:
			$(AS) -f bin -o "$(PROJECT).img" $(SRC)
			$(AS) -f bin -l "$(PROJECT).lst" -o "$(PROJECT)-unfilled.img" -DSKIP_FILL=1 $(SRC)

qemu:		build
			$(QEMU) $(QEMU_FLAGS)

check_size:
			stat --printf="size: %s byte(s)\n" "$(PROJECT)-unfilled.img"

clean:
			rm -f *.o *.lst *.elf *.img *.com *.bin

pytest:
			python3 test.py
