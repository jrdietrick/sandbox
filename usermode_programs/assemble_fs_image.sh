#!/bin/bash
output_file=$1
shift
dd if=/dev/zero bs=512 count=16 status=none > $output_file
offset=0
for file in $@; do
    dd if=$file of=$output_file bs=512 seek=$offset count=1 conv=notrunc status=none
    offset=$((offset+1))
    if ((offset >= 16)); then
        break
    fi
done
