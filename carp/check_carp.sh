#!/bin/sh

usage() {
	echo "$0 iface_num (int)"
	exit 1
}

ret() {
	R=${1}
	if [ "x${R}" = "xOK" ]; then
		RET="0";
	else
		RET="2";
	fi
	echo "${R}: carp${2}: ADVSKEW: ${3}; STATUS: ${4}"
	exit ${RET}
}

IFACE=${1}
if echo ${IFACE} | grep -E '^[0-9]+$' > /dev/null; then :; else usage; fi

STATUS="`ifconfig carp${IFACE} 2>/dev/null | grep "carp:" | awk '{print $2;}'`"
ADVSKEW="`ifconfig carp${IFACE} 2>/dev/null | grep "carp:" | awk '{print $8;}'`"

if [ "x${ADVSKEW}" = "x1" ]; then
	if [ "x${STATUS}" = "xMASTER" ]; then
		ret OK ${IFACE} ${ADVSKEW} ${STATUS}
	else
		ret ERR ${IFACE} ${ADVSKEW} ${STATUS}
	fi
else
	if [ "x${ADVSKEW}" != "x" ]; then
		if [ "x${STATUS}" = "xBACKUP" ]; then
			ret OK ${IFACE} ${ADVSKEW} ${STATUS}
		else
			ret ERR ${IFACE} ${ADVSKEW} ${STATUS}
		fi
	fi
fi
echo "ERR: can't determinate IFACE: carp${IFACE}, STATUS: ${STATUS} or ADVSKEW: ${ADVSKEW}"
