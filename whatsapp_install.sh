#!/bin/sh
set -x

if [ $# -ne 1 ]; then
    echo "usage: $0 VERSION"
    echo "Get VERSION at https://www.whatsapp.com/android/"
    exit 1
fi

app_ver=$1
cd /tmp
wget -qO /tmp/WhatsApp.apk https://www.cdn.whatsapp.net/android/${app_ver}/WhatsApp.apk  > /dev/null 2>&1
adb install -r /tpm/WhatsApp.apk