#!/bin/bash
LOG_PATTERN=$1
BASE_DIR=$(dirname $LOG_PATTERN* | head -1)

run_thread (){
    echo Running thread
    tail -F $LOG_PATTERN* &
    THREAD_PID=$!
}

# When someone decides to stop the script - killall children
cleanup () {
    pgrep -P $$ | xargs -i kill {}
    exit
}

trap cleanup SIGHUP SIGINT SIGTERM

if [ $# -ne 1 ]; then
    echo "usage: $0 <directory/pattern without * in the end>"
    exit 1
fi

# Wait for the directory to be created
if [ ! -d $BASE_DIR ] ; then
    echo DIR $BASE_DIR does not exist, waiting for it...
    while [ ! -d $BASE_DIR ] ; do
        sleep 2
    done
    echo DIR $BASE_DIR is now online
fi

# count current number of files
OLD_NUM_OF_FILES=$(ls -l $LOG_PATTERN* 2>/dev/null | wc -l)

# Start Tailing
run_thread

while [ 1 ]; do
    # If files are added - retail
    NUM_FILES=$(ls -l $LOG_PATTERN* 2>/dev/null | wc -l)
    if [ $NUM_FILES -ne $OLD_NUM_OF_FILES ]; then
        OLD_NUM_OF_FILES=$NUM_FILES
        kill $THREAD_PID
        run_thread
    fi
    sleep 1
done