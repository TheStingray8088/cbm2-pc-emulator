
PRG = dist/prg/6509.prg dist/prg/8088.prg
COM = dist/com/pc_tsr.com dist/com/pc_high.com dist/com/pc_debug.com
ROM = dist/rom/card.bin dist/rom/card_big.bin
MISC = dist/misc/reboot.com dist/misc/cls.com

TRACK = util/160_d80.trk util/160_d82.trk util/180_d80.trk util/180_d82.trk util/360_d80.trk util/360_d82.trk util/720_d82.trk
ONDISK = dist/prg/boot.prg $(PRG)
DISK = dist/disk/pcdos33.d82 dist/disk/pcdos33a.d80 dist/disk/pcdos33b.d80 dist/disk/pcdos11.d82 dist/disk/pcdos11.d80
EMPTY = dist/disk/empty/empty160.d80 dist/disk/empty/empty160.d82 dist/disk/empty/empty180.d80 dist/disk/empty/empty180.d82 dist/disk/empty/empty360.d80 dist/disk/empty/empty360.d82 dist/disk/empty/empty720.d82

COMMON = src/8088/include/data.asm src/8088/include/init.asm src/8088/include/int.asm src/8088/include/ipc.asm src/8088/include/hdrom.asm src/8088/include/version.asm
INSTALL = src/8088/include/install.asm
DEBUG = src/8088/include/debug.asm

all: $(PRG) $(COM) $(ROM) $(MISC) $(TRACK) $(DISK) $(EMPTY)

dist/prg/8088.prg: src/8088/ipc.asm $(COMMON) $(INSTALL)
	nasm src/8088/ipc.asm -o dist/prg/8088.prg

dist/prg/6509.prg: src/6509/ipc.asm
	xa src/6509/ipc.asm -O PETSCII -o dist/prg/6509.prg

dist/com/pc_tsr.com: src/8088/pc_tsr.asm $(COMMON)
	nasm src/8088/pc_tsr.asm -o dist/com/pc_tsr.com

dist/com/pc_high.com: src/8088/pc_high.asm $(COMMON) $(INSTALL)
	nasm src/8088/pc_high.asm -o dist/com/pc_high.com

dist/com/pc_debug.com: src/8088/pc_high.asm $(COMMON) $(INSTALL) $(DEBUG)
	nasm src/8088/pc_high.asm -dDEBUG -o dist/com/pc_debug.com

dist/rom/card.bin: src/8088/rom.asm src/8088/include/rom.asm $(COMMON)
	nasm src/8088/rom.asm -w-lock -o dist/rom/card.bin

dist/rom/card_big.bin: src/8088/rom_big.asm src/8088/include/rom.asm $(COMMON) src/disk/hd.bin
	nasm src/8088/rom_big.asm -w-lock -w-number-overflow -o dist/rom/card_big.bin

dist/misc/reboot.com: src/misc/reboot.asm
	nasm src/misc/reboot.asm -o dist/misc/reboot.com

dist/misc/cls.com: src/misc/cls.asm
	nasm src/misc/cls.asm -o dist/misc/cls.com

util/160_d80.trk: src/track/160_d80.trk $(ONDISK) dist/prg/bamfix/bamfix-160.prg
	util/insert.pl src/track/160_d80.trk util/160_d80.trk $(ONDISK) dist/prg/bamfix/bamfix-160.prg

util/160_d82.trk: src/track/160_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-160.prg
	util/insert.pl src/track/160_d82.trk util/160_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-160.prg

util/180_d80.trk: src/track/180_d80.trk $(ONDISK) dist/prg/bamfix/bamfix-180.prg
	util/insert.pl src/track/180_d80.trk util/180_d80.trk $(ONDISK) dist/prg/bamfix/bamfix-180.prg

util/180_d82.trk: src/track/180_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-180.prg
	util/insert.pl src/track/180_d82.trk util/180_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-180.prg

util/360_d80.trk: src/track/360_d80.trk $(ONDISK) dist/prg/bamfix/bamfix-360.prg
	util/insert.pl src/track/360_d80.trk util/360_d80.trk $(ONDISK) dist/prg/bamfix/bamfix-360.prg

util/360_d82.trk: src/track/360_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-360.prg
	util/insert.pl src/track/360_d82.trk util/360_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-360.prg

util/720_d82.trk: src/track/720_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-720.prg
	util/insert.pl src/track/720_d82.trk util/720_d82.trk $(ONDISK) dist/prg/bamfix/bamfix-720.prg

dist/disk/pcdos33.d82 : util/720_d82.trk src/disk/pcdos33.img
	util/imager.pl -i src/disk/pcdos33.img -o dist/disk/pcdos33.d82 -b util

dist/disk/pcdos33a.d80 : util/360_d80.trk src/disk/pcdos33a.img
	util/imager.pl -i src/disk/pcdos33a.img -o dist/disk/pcdos33a.d80 -b util

dist/disk/pcdos33b.d80 : util/360_d80.trk src/disk/pcdos33b.img
	util/imager.pl -i src/disk/pcdos33b.img -o dist/disk/pcdos33b.d80 -b util

dist/disk/pcdos11.d82 : util/160_d82.trk src/disk/pcdos11.img
	util/imager.pl -i src/disk/pcdos11.img -o dist/disk/pcdos11.d82 -b util

dist/disk/pcdos11.d80 : util/160_d80.trk src/disk/pcdos11.img
	util/imager.pl -i src/disk/pcdos11.img -o dist/disk/pcdos11.d80 -b util

dist/disk/empty/empty160.d80 : util/160_d80.trk src/disk/empty/empty160.img
	util/imager.pl -i src/disk/empty/empty160.img -o dist/disk/empty/empty160.d80 -b util

dist/disk/empty/empty160.d82 : util/160_d82.trk src/disk/empty/empty160.img
	util/imager.pl -i src/disk/empty/empty160.img -o dist/disk/empty/empty160.d82 -b util

dist/disk/empty/empty180.d80 : util/180_d80.trk src/disk/empty/empty180.img
	util/imager.pl -i src/disk/empty/empty180.img -o dist/disk/empty/empty180.d80 -b util

dist/disk/empty/empty180.d82 : util/180_d82.trk src/disk/empty/empty180.img
	util/imager.pl -i src/disk/empty/empty180.img -o dist/disk/empty/empty180.d82 -b util

dist/disk/empty/empty360.d80 : util/360_d80.trk src/disk/empty/empty360.img
	util/imager.pl -i src/disk/empty/empty360.img -o dist/disk/empty/empty360.d80 -b util

dist/disk/empty/empty360.d82 : util/360_d82.trk src/disk/empty/empty360.img
	util/imager.pl -i src/disk/empty/empty360.img -o dist/disk/empty/empty360.d82 -b util

dist/disk/empty/empty720.d82 : util/720_d82.trk src/disk/empty/empty720.img
	util/imager.pl -i src/disk/empty/empty720.img -o dist/disk/empty/empty720.d82 -b util
