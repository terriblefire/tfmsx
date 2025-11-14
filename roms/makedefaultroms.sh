#!/bin/bash

# wget http://www.msxarchive.nl/pub/msx/emulator/openMSX/systemroms.zip
# unzip systemroms.zip

rm -f *.rom* bank* default.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2EXT.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2BR.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2BREXT.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/DISK.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2P.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2PEXT.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2SP.rom
wget http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms/MSX2SPEXT.rom

cat MSX2.rom MSX2EXT.rom DISK.rom > bank0
cat MSX2BR.rom MSX2BREXT.rom DISK.rom > bank1
cat MSX2P.rom MSX2PEXT.rom DISK.rom > bank2
cat MSX2SP.rom MSX2SPEXT.rom DISK.rom > bank3

cat bank0 bank1 bank2 bank3 > default.rom
