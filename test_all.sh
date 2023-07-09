#!/bin/bash
./ensure_directories_exist.sh

TEST_SOURCES="test_sources/*.S"
( ls -1 $TEST_SOURCES \
| sed -e 's/^.*\//.\/compile_test.sh /' -e 's/.S/ | .\/condense_test_run_into_test_point.awk/' \
| bash \
; echo -n '1..' \
; ( ls -1 $TEST_SOURCES \
  | wc -l \
  )
)
