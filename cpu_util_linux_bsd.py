#!/usr/bin/env python
#
#       Simple script to monitor CPU utilization on FreeBSD or Linux.
#

from platform import system
from time import sleep

from os import strerror
from sys import stderr, exit

debug = False
interval = 1    # pause interval in seconds
os = system()

def countCpu(cptime_0, cptime_1):
    cp_diff = [cptime_1[i] - cptime_0[i] for i in range(len(cptime_0))]
    cp_total = sum(cp_diff)
    cp_cpu = cp_total - cp_diff[-1]
    res = int(round((100.0 * cp_cpu) / cp_total))
    return res

if os == "FreeBSD":

    from ctypes import *
    libc = CDLL("libc.so")
    errno = c_int.in_dll(libc, "errno")

    def check_fail (fail):
        if fail:
            exit (1)
        else:
            return None

    def sysctlnametomib (name, fail = True):
        mibsize = len(name.split('.'))
        size = c_uint(mibsize)
        mib = (c_int * mibsize)()
        if libc.sysctlnametomib(name, byref(mib), byref(size)) != 0:
            print >> stderr, 'sysctlnametomib("%s"):' % name, strerror(errno.value)
            return check_fail(fail)
        if debug:
            print >> stderr, 'sysctlnametomib("%s") -->' % name, str(list(mib))
        return mib

    def sysctl_ulongarray (mib, count = None, fail = True):
        return sysctl_numericarray(c_ulong, mib, count, fail)

    def sysctl_numericarray (type, mib, count = None, fail = True):
        if count is None:
            size = c_uint(0)
            if libc.sysctl(byref(mib), len(mib), None, byref(size), None, 0) != 0:
                print >> stderr, 'sysctl(%s):' % str(list(mib)), strerror(errno.value)
                return check_fail(fail)
            if debug:
                print >> stderr, 'sysctl(%s) --> size' % str(list(mib)), size.value
            count = size.value / sizeof(type)
        else:
            size = c_uint(count * sizeof(type))
        value = (type * count)()
        if libc.sysctl(byref(mib), len(mib), byref(value), byref(size), None, 0) != 0:
            print >> stderr, 'sysctl(%s):' % str(list(mib)), strerror(errno.value)
            return check_fail(fail)
        if debug:
            print >> stderr, 'sysctl(%s) -->' % str(list(mib)), repr(list(value))
        return list(value)

    def getTimeList():
        return sysctl_ulongarray(kern_cptime, 5)

    kern_cptime = sysctlnametomib("kern.cp_time")

if os == "Linux":
    def getTimeList():
        statFile = file("/proc/stat", "r")
        timeList = statFile.readline().split(" ")[2:6]
        statFile.close()
        for i in range(len(timeList))  :
            timeList[i] = int(timeList[i])
        return timeList

while True:
    cptime_0 = getTimeList()
    sleep (interval)
    cptime_1 = getTimeList()

    print countCpu(cptime_0, cptime_1)
