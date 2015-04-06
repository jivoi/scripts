#!/usr/bin/env python

import os
import signal
import subprocess
import time
import re

# Change this to your process name
processname = '/usr/local/apache2/bin/httpd'
user = 'www'

pids = {}

out, err = subprocess.Popen(['ps', 'xwww', '-U', user, '-O', 'ppid'], stdout=subprocess.PIPE).communicate()

for line in out.splitlines():
        col = line.split()
        pid = col[0]
        ppid = col[1]
        process = col[5:]

        if re.search(processname, line):
                pids[ppid] = pid

for ppid in pids:
        for pid in pids.values():
                if ppid == pid:
                        kill_pid = int(pids[ppid])
                        try:
                                time.sleep(0.5)
                                os.kill(kill_pid, 0)
                                print "kill -9", kill_pid
                                os.kill(kill_pid, signal.SIGKILL)
                        except:
                                pass
