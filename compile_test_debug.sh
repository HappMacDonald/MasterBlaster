#!/bin/bash
./ensure_directories_exist.sh

SOURCE_A="test_sources/$1.S"
SOURCE_B="build/$1.S"
EXECUTABLE="test_binaries/$1.elf64"
./crude_preprocessor.awk $SOURCE_A > $SOURCE_B \
&& gcc -Iinclude -fPIC -nostartfiles -nostdlib -Wall -g -ggdb -gdwarf-4 -g3 -F dwarf -m64 $SOURCE_B sources/libmb_s.S -o $EXECUTABLE \
&& ( gdb $EXECUTABLE )
