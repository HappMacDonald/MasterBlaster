#!/bin/bash
./ensure_directories_exist.sh

./test_all.sh | ./tapsummary.awk
