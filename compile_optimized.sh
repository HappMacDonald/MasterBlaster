#!/bin/bash
./ensure_directories_exist.sh

SOURCE_NAME=$1
SOURCE_A="sources/$SOURCE_NAME.S"
SOURCE_B="build/$SOURCE_NAME.S"
SOURCE_LIB_MB_A="sources/libmb_s.S"
SOURCE_LIB_MB_B="build/libmb_s.S"
EXECUTABLE="test_binaries/$SOURCE_NAME.elf64"

./crude_preprocessor.awk $SOURCE_A > $SOURCE_B
./crude_preprocessor.awk $SOURCE_LIB_MB_A > $SOURCE_LIB_MB_B
gcc -Iinclude -fpic -nostartfiles -nostdlib -Wall -g -gdwarf-4 -g3 -F dwarf -m64 $SOURCE_B $SOURCE_LIB_MB_B -o $EXECUTABLE && ( time $EXECUTABLE; printf 'Return value was: %X = %d\n' $? $? )
