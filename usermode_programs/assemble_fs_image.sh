#!/bin/bash
output_file=$1
shift
dd if=/dev/zero bs=512 count=32 status=none > $output_file
offset=0
for file in $@; do
    dd if=$file of=$output_file bs=512 seek=$((offset*8)) count=8 conv=notrunc status=none
    offset=$((offset+1))
    if ((offset >= 4)); then
        break
    fi
done
