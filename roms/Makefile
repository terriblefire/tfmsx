# Makefile for MSX ROM management
# Refactored from makedefaultroms.sh

# Base URL for ROM downloads
BASE_URL = http://msx2.org/DVD_MSX/Emuladores/BlueMSX%202.8.2/Machines/Shared%20Roms

# ROM files to download
ROM_FILES = MSX2.rom MSX2EXT.rom MSX2BR.rom MSX2BREXT.rom DISK.rom \
            MSX2P.rom MSX2PEXT.rom MSX2SP.rom MSX2SPEXT.rom

# Bank files
BANKS = bank0 bank1 bank2 bank3

# Final output
OUTPUT = default.rom

.PHONY: all clean

all: $(OUTPUT)

# Download individual ROM files
%.rom:
	wget $(BASE_URL)/$@

# Create bank0: MSX2 + MSX2EXT + DISK
bank0: MSX2.rom MSX2EXT.rom DISK.rom
	cat MSX2.rom MSX2EXT.rom DISK.rom > $@

# Create bank1: MSX2BR + MSX2BREXT + DISK
bank1: MSX2BR.rom MSX2BREXT.rom DISK.rom
	cat MSX2BR.rom MSX2BREXT.rom DISK.rom > $@

# Create bank2: MSX2P + MSX2PEXT + DISK
bank2: MSX2P.rom MSX2PEXT.rom DISK.rom
	cat MSX2P.rom MSX2PEXT.rom DISK.rom > $@

# Create bank3: MSX2SP + MSX2SPEXT + DISK
bank3: MSX2SP.rom MSX2SPEXT.rom DISK.rom
	cat MSX2SP.rom MSX2SPEXT.rom DISK.rom > $@

# Create final default.rom from all banks
$(OUTPUT): $(BANKS)
	cat $(BANKS) > $@

# Clean all generated files
clean:
	rm -f $(ROM_FILES) $(BANKS) $(OUTPUT)
