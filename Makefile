
all: country.sys

country.sys: country.asm
	nasm -o $@ $<

clean:
	$(RM) country.sys
