gcc -fPIC -nostartfiles -nostdlib -Wall -g -ggdb -gdwarf-4 -g3 -F dwarf -m64 "$1.S" sources/libmb_s.S -o "$1.elf64" && ( gdb "./$1.elf64" )
