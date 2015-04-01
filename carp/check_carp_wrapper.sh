#!/bin/sh

for i in `jot - 0 5`; do
	STATUS=`/root/bin/check_carp.sh ${i}`
	if echo ${STATUS} | grep OK > /dev/null; then :; else echo -n "${STATUS}"; F=1; fi
done

if [ "x${F}" != 1 ]; then echo -n " "; fi
