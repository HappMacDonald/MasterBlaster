gcc -fpic -nostartfiles -nostdlib -Wall -g -gdwarf-4 -g3 -F dwarf -m64 "$1.S" libmb_s.S -o "$1.elf64" && ( time "./$1.elf64"; echo $? )
