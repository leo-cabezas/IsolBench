#!/bin/bash
# single bank version of mlptest

#mount -t hugetlbfs none /mnt/huge
#echo 128 > /proc/sys/vm/nr_hugepages
. ./functions
. ./floatfunc

if [ -z "$1" -o -z "$2" ]; then
    echo "usage: llctest-1bank.sh <maxmlp> <corun> [<startcore>]" >&2
    exit 1
fi

mlp=$1
corun=$2
memsize=6000 # in KB
unitsize=64

echoerr() { echo "$@" 1>&2; }

[ -z "$3" ] && st=0 || st=$3

c_start=`expr $st + 1`
c_end=`expr $st + $corun`

killall pll >& /dev/null

for l in `seq 1 $mlp`; do
    for c in `seq $c_start $c_end`; do
	    pll -c $c -l $l -u $unitsize -i 10000000 -k $memsize -f llcmap.txt -e 0 >& /tmp/pll-$l-$c.log &
    done
    sleep 0.5
    pll -c $st -l $l -u $unitsize -i 100 -k $memsize -f llcmap.txt -e 0 2> /tmp/err.txt

    if grep -qi "alloc failed" /tmp/err.txt; then
        echo "Error: Failed to allocate memory for mlp $l, please allocate more hugepages." >&2
        echo "Hint: Check /proc/meminfo and init-hugetlbfs.sh" >&2
        exit 1
    fi
    killall pll >& /dev/null
    echoerr  $l `tail -n 1 /tmp/test.txt`
done  > /tmp/test.txt
BWS=`grep bandwidth /tmp/test.txt | awk '{ print $2 }'`

for b in $BWS; do
    echo $b
done > out.txt
cat out.txt
