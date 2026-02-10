
all: country.sys

production: country.sys
	$(CP) country.sys ..$(DIRSEP)bin

country.sys: country.asm
	nasm -o $@ -l $(basename $<).lst country.asm

clean:
	$(RM) country.sys

clobber: clean
