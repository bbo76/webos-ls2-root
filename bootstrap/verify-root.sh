#!/bin/sh

OUT=/media/developer/temp/ls2root-v01/result.txt

{
    echo "=== LS2 ROOT V0.1 ==="
    date
    id
    cat /proc/sys/kernel/random/boot_id
    cat /proc/uptime
} > "$OUT" 2>&1