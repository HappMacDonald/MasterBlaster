./crude_preprocessor.pl "testSources/$1.S" > "build/$1.S" \
&& gcc -Iinclude -fPIC -nostartfiles -nostdlib -Wall -g -ggdb -gdwarf-4 -g3 -F dwarf -m64 "build/$1.S" sources/libmb_s.S -o "binaries/$1.elf64" \
&& ( gdb "binaries/$1.elf64" )
