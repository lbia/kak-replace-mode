ansi:
	c89 -Wall -o replace-mode replace-mode.c
c89:
	c89 -Wall -o replace-mode-c89 replace-mode.c
c99:
	c99 -Wall -o replace-mode-c99 replace-mode.c
gcc:
	gcc -Wall -o replace-mode-gcc replace-mode.c
all: ansi c89 c99 gcc
clear:
	rm -f \
		replace-mode \
		replace-mode-c89 \
		replace-mode-c99 \
		replace-mode-gcc
