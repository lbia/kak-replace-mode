ansi:
	c89 -o replace-mode replace-mode.c -Wall
c89:
	c89 -o replace-mode-c89 replace-mode.c -Wall
c99:
	c99 -o replace-mode-c99 replace-mode.c -Wall
gcc:
	gcc -o replace-mode-gcc replace-mode.c -Wall
all: ansi c89 c99 gcc
clear:
	rm -f \
		replace-mode \
		replace-mode-c89 \
		replace-mode-c99 \
		replace-mode-gcc
