#!/bin/bash
./ensure_directories_exist.sh

./crude_preprocessor.pl "sources/$1.S" > "build/$1.S"
gcc -Iinclude -fpic -nostartfiles -nostdlib -Wall -g -gdwarf-4 -g3 -F dwarf -m64 "build/$1.S" sources/libmb_s.S -o "binaries/$1.elf64" && ( time "binaries/$1.elf64"; printf 'Return value was: %X = %d\n' $? $? )
