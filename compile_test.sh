#!/bin/bash
./ensure_directories_exist.sh

set -o pipefail
test=$1
SOURCE_A="test_sources/$test.S"
SOURCE_B="build/$test.S"
SOURCE_LIB_MB_A="sources/libmb_s.S"
SOURCE_LIB_MB_B="build/libmb_s.S"
EXECUTABLE="test_binaries/$test.elf64"
printf 'Running test "%s":\n' "$SOURCE_A"
if \
( ./crude_preprocessor.awk $SOURCE_A > $SOURCE_B \
  && ./crude_preprocessor.awk $SOURCE_LIB_MB_A > $SOURCE_LIB_MB_B \
  && gcc -Iinclude -fPIC -nostartfiles -nostdlib -Wall -g -ggdb -gdwarf-4 -g3 -F dwarf -m64 $SOURCE_B $SOURCE_LIB_MB_B -o $EXECUTABLE \
)
then
   $EXECUTABLE | ./tapsummary.awk
   printf '%s | ./tapsummary.awk pipe return value was: %s\n' $EXECUTABLE $?
else
   printf './crude_preprocessor.awk && gcc return value was: %s\n' $?
fi
