#!/bin/bash
./ensure_directories_exist.sh

SOURCE_A="test_sources/$1.S"
SOURCE_B="build/$1.S"
SOURCE_LIB_MB_A="sources/libmb_s.S"
SOURCE_LIB_MB_B="build/libmb_s.S"
EXECUTABLE="test_binaries/$1.elf64"
./crude_preprocessor.awk $SOURCE_A > $SOURCE_B \
&& ./crude_preprocessor.awk $SOURCE_LIB_MB_A > $SOURCE_LIB_MB_B \
&& gcc -Iinclude -fPIC -nostartfiles -nostdlib -Wall -g -ggdb -gdwarf-4 -g3 -F dwarf -m64 $SOURCE_B $SOURCE_LIB_MB_B -o $EXECUTABLE \
&& ( gdb $EXECUTABLE )
