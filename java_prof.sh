#!/bin/bash
# The idea of the script is based on the method from poor man’s profiler adapted for HotSpot thread dumps. The script does the following things:

# - Takes $P_CNT thread dumps of the Java process ID passed as $1 (10 by default)
# - If a native thread ID has been supplied as $2, then searches for the thread stack of this thread in the thread dump
# - Concatenates each thread stack trace into a comma-separated string
# - Aggregates strings and sorts them by the number of occurrences
# - Prettifies the output: removes tabs, commas, and adds new lines back to the thread stack

# ./prof.sh 7599 7601

# For monitoring JVM I’d also recommend a jvmtop tool (https://github.com/patric-r/jvmtop).

# Installl (needs Java to be installed and accessible):
# curl -sL “https://github.com/patric-r/jvmtop/releases/download/0.8.0/jvmtop-0.8.0.tar.gz” | gunzip | tar -x -C /bin/ && mv /bin/jvmtop.sh /bin/jvmtop && chmod +x /bin/jvmtop

# Execute:
# jvmtop

P_PID=$1
P_NID=$2

if [ "$P_SLEEP" == "" ]; then
  P_SLEEP=0.5
fi

if [ "$P_CNT" == "" ]; then
  P_CNT=10
fi

echo Sampling PID=$P_PID every $P_SLEEP seconds for $P_CNT samples

if [ "$P_NID" == "" ]; then
  CMD="awk '//'"
else
  CMD="awk '/ nid='"$(printf '%#x' $P_NID)"' /,/^$/'"
fi

for i in `seq $P_CNT`
do
  jstack $P_PID | eval $CMD
  sleep $P_SLEEP;
done |
  awk ' BEGIN { x = 0; s = "" }
    /nid=/ { x = 1; }
    // {if (x == 1) {s = s ", "gensub(/<\w*>/, "<address>", "g") } }
    /^$/ { if ( x == 1) { print s; x = 0; s = ""; } }' |
  sort | uniq -c | sort -n -r | head -10 |
  sed -e 's/$/\n/g' -e 's/\t/\n\t/g' -e 's/,//g'