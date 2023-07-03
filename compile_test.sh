#!/bin/bash
set -o pipefail
test=$1
SOURCE_A="test_sources/$test.S"
SOURCE_B="build/$test.S"
EXECUTABLE="test_binaries/$test.elf64"
printf 'Running test "%s":\n' "$SOURCE_A"
if \
( ./crude_preprocessor.pl $SOURCE_A > $SOURCE_B \
  && gcc -Iinclude -fPIC -nostartfiles -nostdlib -Wall -g -ggdb -gdwarf-4 -g3 -F dwarf -m64 $SOURCE_B sources/libmb_s.S -o $EXECUTABLE \
)
then
   $EXECUTABLE | ./tapsummary.awk
   printf '%s | ./tapsummary.awk pipe return value was: %s\n' $EXECUTABLE $?
else
   printf './crude_preprocessor.pl && gcc return value was: %s\n' $?
fi
